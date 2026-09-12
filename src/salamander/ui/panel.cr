# salamander/src/salamander/ui/panel.cr
# Copyright (C) 2026 Cam Carroll
# Licensed under the AGPL-3.0. See LICENSE for details.

require "./theme"

class Salamander::UI
  # Reusable bordered card / panel drawing primitive.
  # Handles exact ANSI-aware visible width calculations, rounded borders,
  # badges, dividers, and content rows.
  class Panel
    getter width : Int32
    property box_style : BoxStyle

    def initialize(@width : Int32, @box_style : BoxStyle = BoxStyle::Rounded)
      @width = Math.max(20, @width)
    end

    def inner_w : Int32
      @width - 4
    end

    # Clamps terminal width to a readable max width (default 105) on ultra-wide screens
    def self.clamp_width(term_width : Int32, max_width : Int32 = 105, padding : Int32 = 4) : Int32
      clamped = Math.min(term_width - padding, max_width)
      Math.max(20, clamped)
    end

    # Strips ANSI escape sequences to compute raw strings
    def strip_ansi(str : String) : String
      self.class.strip_ansi(str)
    end

    def self.strip_ansi(str : String) : String
      str.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
    end

    # Computes exact visual monospace column width, stripping ANSI and accounting for wide Unicode/emojis
    def visual_width(str : String) : Int32
      self.class.visual_width(str)
    end

    def self.visual_width(str : String) : Int32
      clean = strip_ansi(str)
      w = 0
      clean.each_char do |c|
        w += Salamander::UI.char_width(c)
      end
      w
    end

    # Truncates a string (preserving ANSI codes) so its visual column width is at most max_w
    def self.truncate_visual(str : String, max_w : Int32, ellipsis : String = "...") : String
      return str if visual_width(str) <= max_w

      el_w = visual_width(ellipsis)
      target_w = Math.max(0, max_w - el_w)
      in_ansi = false
      cur_w = 0
      result = IO::Memory.new

      str.each_char do |c|
        if c == '\e'
          in_ansi = true
          result << c
        elsif in_ansi
          result << c
          in_ansi = false if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
        else
          char_w = Salamander::UI.char_width(c)
          break if cur_w + char_w > target_w
          cur_w += char_w
          result << c
        end
      end

      result << "\e[0m" if str.includes?("\e[")
      result << ellipsis
      result.to_s
    end

    # Word-wraps text into lines that each fit within max_width visual columns
    def self.wrap_text(text : String, max_width : Int32) : Array(String)
      lines = [] of String
      text.each_line do |paragraph|
        words = paragraph.split(' ')
        current_line = IO::Memory.new
        current_w = 0

        words.each do |word|
          w_len = visual_width(word)
          if current_w == 0
            if w_len > max_width
              lines << truncate_visual(word, max_width)
            else
              current_line << word
              current_w = w_len
            end
          elsif current_w + 1 + w_len <= max_width
            current_line << " " << word
            current_w += 1 + w_len
          else
            lines << current_line.to_s
            current_line = IO::Memory.new
            if w_len > max_width
              lines << truncate_visual(word, max_width)
              current_w = 0
            else
              current_line << word
              current_w = w_len
            end
          end
        end
        lines << current_line.to_s if current_w > 0
      end
      lines.empty? ? [""] : lines
    end

    # Renders the top border of the panel with a title and optional right-aligned badge.
    # Strictly guarantees the total output visual width is exactly @width columns.
    def render_header(title : String, badge : String? = nil, border_color : String = Theme::BORDER, style : BoxStyle? = nil) : String
      active_style = style || @box_style
      tl, tr, fill = case active_style
      when BoxStyle::Armored
        {"╔═", "╗", "═"}
      when BoxStyle::Sharp
        {"┌─", "┐", "─"}
      else
        {"╭─", "╮", "─"}
      end

      title_w = visual_width(title)
      active_badge = (badge && !badge.empty?) ? badge : nil
      badge_w = active_badge ? visual_width(active_badge) : 0

      if active_badge
        rem = @width - 7 - title_w - badge_w
        if rem < 0
          # Not enough room for both title and badge. Drop the badge first.
          rem_no_badge = @width - 5 - title_w
          if rem_no_badge >= 0
            "#{border_color}#{tl}#{Theme::RESET} #{title} #{border_color}#{fill * rem_no_badge}#{tr}#{Theme::RESET}"
          else
            max_t = Math.max(0, @width - 6)
            trunc_title = self.class.truncate_visual(title, max_t)
            rem_trunc = Math.max(0, @width - 5 - visual_width(trunc_title))
            "#{border_color}#{tl}#{Theme::RESET} #{trunc_title} #{border_color}#{fill * rem_trunc}#{tr}#{Theme::RESET}"
          end
        else
          "#{border_color}#{tl}#{Theme::RESET} #{title} #{border_color}#{fill * rem}#{Theme::RESET} #{active_badge} #{border_color}#{tr}#{Theme::RESET}"
        end
      else
        rem = @width - 5 - title_w
        if rem < 0
          max_t = Math.max(0, @width - 6)
          trunc_title = self.class.truncate_visual(title, max_t)
          rem_trunc = Math.max(0, @width - 5 - visual_width(trunc_title))
          "#{border_color}#{tl}#{Theme::RESET} #{trunc_title} #{border_color}#{fill * rem_trunc}#{tr}#{Theme::RESET}"
        else
          "#{border_color}#{tl}#{Theme::RESET} #{title} #{border_color}#{fill * rem}#{tr}#{Theme::RESET}"
        end
      end
    end

    # Renders a padded content row bounded by left and right borders.
    # When content fits within inner_w, strictly guarantees the total output visual width is exactly @width columns.
    # If truncate is true, content exceeding inner_w is cleanly truncated to fit.
    def render_row(content : String, border_color : String = Theme::BORDER, style : BoxStyle? = nil, truncate : Bool = false) : String
      active_style = style || @box_style
      raw_len = visual_width(content)
      safe_content = if truncate && raw_len > inner_w
        self.class.truncate_visual(content, inner_w)
      else
        content
      end
      safe_len = visual_width(safe_content)
      pad = Math.max(0, inner_w - safe_len)
      v = (active_style == BoxStyle::Armored) ? "║" : "│"
      "#{border_color}#{v}#{Theme::RESET} #{safe_content}#{" " * pad} #{border_color}#{v}#{Theme::RESET}"
    end

    # Renders wrapped content rows, each strictly bounded by left and right borders
    def render_wrapped_row(content : String, border_color : String = Theme::BORDER, style : BoxStyle? = nil, max_lines : Int32? = nil) : Array(String)
      lines = self.class.wrap_text(content, inner_w)
      if max_l = max_lines
        if lines.size > max_l
          lines = lines[0...max_l]
          last = lines.last
          lines[lines.size - 1] = self.class.truncate_visual(last, inner_w)
        end
      end
      lines.map { |l| render_row(l, border_color, style, truncate: true) }
    end

    # Renders a horizontal divider within the panel.
    # Strictly guarantees the total output visual width is exactly @width columns.
    def render_divider(border_color : String = Theme::BORDER, style : BoxStyle? = nil) : String
      active_style = style || @box_style
      dl, dr, fill = case active_style
      when BoxStyle::Armored
        {"╠", "╣", "═"}
      when BoxStyle::Sharp
        {"├", "┤", "─"}
      else
        {"├", "┤", "─"}
      end
      "#{border_color}#{dl}#{fill * (inner_w + 2)}#{dr}#{Theme::RESET}"
    end

    # Renders the bottom closing border of the panel.
    # Strictly guarantees the total output visual width is exactly @width columns.
    def render_footer(border_color : String = Theme::BORDER, style : BoxStyle? = nil) : String
      active_style = style || @box_style
      bl, br, fill = case active_style
      when BoxStyle::Armored
        {"╚", "╝", "═"}
      when BoxStyle::Sharp
        {"└", "┘", "─"}
      else
        {"╰", "╯", "─"}
      end
      "#{border_color}#{bl}#{fill * (inner_w + 2)}#{br}#{Theme::RESET}"
    end
  end
end
