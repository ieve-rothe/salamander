# src/salamander/fuzzy.cr
# Copyright (C) 2026 Cam Carroll
# Licensed under the MIT License. See LICENSE for details.

require "colorize"

module Salamander
  # Fuzzy matching and command resolution utilities for terminal CLIs and REPLs.
  module Fuzzy
    extend self

    enum Action
      Execute
      SendPrompt
      Cancel
    end

    # Calculates the Damerau-Levenshtein distance between two strings,
    # counting insertions, deletions, substitutions, and adjacent transpositions as 1 edit.
    def distance(source : String, target : String) : Int32
      source_len = source.size
      target_len = target.size

      return target_len if source_len == 0
      return source_len if target_len == 0

      d = Array.new(source_len + 1) { Array(Int32).new(target_len + 1, 0) }

      (0..source_len).each { |i| d[i][0] = i }
      (0..target_len).each { |j| d[0][j] = j }

      (1..source_len).each do |i|
        s_char = source[i - 1]
        (1..target_len).each do |j|
          t_char = target[j - 1]
          cost = (s_char == t_char) ? 0 : 1

          d[i][j] = Math.min(
            d[i - 1][j] + 1,
            Math.min(
              d[i][j - 1] + 1,
              d[i - 1][j - 1] + cost
            )
          )

          # Transposition of adjacent characters (Damerau)
          if i > 1 && j > 1 && s_char == target[j - 2] && source[i - 2] == t_char
            d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1)
          end
        end
      end

      d[source_len][target_len]
    end

    # Checks whether characters of `sub` appear in `full` in the same sequential order.
    def subsequence?(sub : String, full : String) : Bool
      return false if sub.empty? || full.empty?
      sub_idx = 0
      full.each_char do |c|
        if c == sub[sub_idx]
          sub_idx += 1
          return true if sub_idx == sub.size
        end
      end
      false
    end

    # Calculates a multi-heuristic similarity score [0.0..1.0] between input and candidate.
    # Combines Damerau-Levenshtein ratio with word/token overlap, substring, and subsequence heuristics.
    def similarity(input : String, candidate : String) : Float64
      clean_input = input.lstrip("/-").downcase
      clean_cand = candidate.lstrip("/-").downcase

      return 1.0 if clean_input == clean_cand
      return 0.0 if clean_input.empty? || clean_cand.empty?

      max_len = Math.max(input.size, candidate.size)
      lev_dist = distance(input.downcase, candidate.downcase)
      lev_sim = max_len > 0 ? (1.0 - (lev_dist.to_f / max_len)) : 0.0

      input_words = clean_input.split(/[\s_\-]+/).reject(&.empty?)
      cand_words = clean_cand.split(/[\s_\-]+/).reject(&.empty?)

      common_words = input_words & cand_words
      token_bonus = input_words.size > 0 ? (common_words.size.to_f / input_words.size) * 0.5 : 0.0

      has_substring = clean_input.size >= 3 && clean_cand.size >= 3 &&
                      (clean_cand.includes?(clean_input) || clean_input.includes?(clean_cand))
      substring_bonus = has_substring ? 0.4 : 0.0

      has_subseq = clean_input.size >= 3 && clean_cand.size >= 3 && subsequence?(clean_input, clean_cand)
      subseq_bonus = has_subseq ? 0.35 : 0.0

      # Length consistency bonus (rewards candidates of matching length when distance is tied)
      len_diff = (clean_input.size - clean_cand.size).abs
      len_bonus = max_len > 0 ? (1.0 - (len_diff.to_f / max_len)) * 0.15 : 0.0

      # Multiset match bonus (e.g. transpositions with exact same letters)
      same_letters = (clean_input.size == clean_cand.size) && (clean_input.chars.sort == clean_cand.chars.sort)
      char_bonus = same_letters ? 0.2 : 0.0

      has_word_match = !common_words.empty?

      score = lev_sim + token_bonus + substring_bonus + subseq_bonus + len_bonus + char_bonus
      is_valid = if has_word_match || has_substring || has_subseq || same_letters
                   score >= 0.4
                 else
                   lev_sim >= 0.65
                 end

      is_valid ? score : 0.0
    end

    # Finds the single closest matching candidate, or nil if no candidate satisfies the threshold.
    def find_closest(input : String, candidates : Enumerable(String), threshold : Float64 = 0.4) : String?
      best_candidate = nil
      best_score = threshold

      candidates.each do |cand|
        sc = similarity(input, cand)
        if sc > best_score
          best_score = sc
          best_candidate = cand
        end
      end

      best_candidate
    end

    # Finds the top N closest matching candidates sorted by score descending.
    def find_top(input : String, candidates : Enumerable(String), limit : Int32 = 3, threshold : Float64 = 0.4) : Array(Tuple(String, Float64))
      matches = [] of Tuple(String, Float64)

      candidates.each do |cand|
        sc = similarity(input, cand)
        if sc >= threshold
          matches << {cand, sc}
        end
      end

      matches.sort_by { |(_, sc)| -sc }.first(limit)
    end

    # Formats a "Did you mean ...?" suggestion string with ANSI color when enabled.
    def did_you_mean(input : String, candidates : Enumerable(String), threshold : Float64 = 0.4) : String?
      if closest = find_closest(input, candidates, threshold)
        if STDOUT.tty?
          "Did you mean #{closest.colorize(:yellow)}?"
        else
          "Did you mean #{closest}?"
        end
      end
    end

    # Presents a standardized 3-option menu for unrecognized slash commands in interactive REPLs.
    def choose_action(
      input : String,
      closest : String?,
      stdin : IO = STDIN,
      stdout : IO = STDOUT,
      stderr : IO = STDERR,
    ) : Tuple(Action, String)
      stderr.puts "[System] Error: Unknown command '#{input}'.".colorize(:red)
      if closest
        stderr.puts "Did you mean #{closest.colorize(:yellow)}?"
      end

      stdout.puts "\nUnrecognized slash command options:".colorize(:light_cyan)
      if closest
        stdout.puts "  1. Execute '#{closest}'".colorize(:yellow)
        stdout.puts "  2. Send '#{input}' as prompt to model".colorize(:yellow)
        stdout.puts "  3. Cancel input".colorize(:yellow)
        stdout.print "Select option [1-3] (default: 3): ".colorize(:cyan)
        choice = stdin.gets.try(&.strip)
        case choice
        when "1"
          {Action::Execute, closest}
        when "2"
          {Action::SendPrompt, input}
        else
          stdout.puts "Cancelled.".colorize(:dark_gray)
          {Action::Cancel, ""}
        end
      else
        stdout.puts "  1. Send '#{input}' as prompt to model".colorize(:yellow)
        stdout.puts "  2. Cancel input".colorize(:yellow)
        stdout.print "Select option [1-2] (default: 2): ".colorize(:cyan)
        choice = stdin.gets.try(&.strip)
        case choice
        when "1"
          {Action::SendPrompt, input}
        else
          stdout.puts "Cancelled.".colorize(:dark_gray)
          {Action::Cancel, ""}
        end
      end
    end
  end
end
