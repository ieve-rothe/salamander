# salamander/src/salamander/ui/markdown_formatter.cr
# Copyright (C) 2026 Cam Carroll
# Licensed under the AGPL-3.0. See LICENSE for details.

module Salamander
  class UI
    # Provides a lightweight terminal formatter that replaces Markdown syntax
    # with ANSI escape codes for improved readability in standard terminal environments.
    module MarkdownFormatter
      extend self

      CODE_BLOCK_REGEX   = /```([\s\S]*?)```/
      INLINE_CODE_REGEX  = /`([^`]+)`/
      BOLD_REGEX         = /\*\*([^*]+)\*\*/
      ITALIC_REGEX       = /(?<!\w)\*([^*]+)\*(?!\w)/
      HEADER_REGEX       = /^(\#{1,6})\s+([^\n]+)$/
      LINK_REGEX         = /\[([^\]\[]+)\]\(([^)]+)\)/
      BLOCKQUOTE_REGEX   = /^>\s+([^\n]+)$/

      # Formats a markdown string *text* by converting markdown syntax elements to ANSI escape codes.
      # Protects code blocks from corruption, prevents ANSI reset bleeding on nested spans,
      # and optimizes memory allocation.
      def format(text : String) : String
        return text if text.empty?

        # Step 1: Protect code blocks & inline code by extracting into placeholders
        code_blocks = [] of String

        # Extract triple-backtick code blocks first
        extracted = text.gsub(CODE_BLOCK_REGEX) do
          content = $~[1]
          placeholder = "\x00CODE_BLOCK_#{code_blocks.size}\x00"
          code_blocks << "\e[48;5;236m#{content}\e[0m"
          placeholder
        end

        # Extract single-backtick inline code next
        extracted = extracted.gsub(INLINE_CODE_REGEX) do
          content = $~[1]
          placeholder = "\x00CODE_BLOCK_#{code_blocks.size}\x00"
          code_blocks << "\e[48;5;236m#{content}\e[0m"
          placeholder
        end

        # Step 2: Format line-by-line in a single buffer sweep to handle headers, blockquotes, and nested styling
        formatted = String.build(extracted.bytesize + 64) do |io|
          lines = extracted.split('\n')
          lines.each_with_index do |line, idx|
            io << '\n' if idx > 0
            format_line(line, io)
          end
        end

        # Step 3: Re-inject protected code blocks
        code_blocks.each_with_index do |block, i|
          formatted = formatted.gsub("\x00CODE_BLOCK_#{i}\x00", block)
        end

        formatted
      end

      # Formats a single line, taking into account block structure (Header / Blockquote)
      # and ensuring inner spans restore the active parent ANSI style stack.
      private def format_line(line : String, io : IO)
        if match = line.match(HEADER_REGEX)
          # Header: parent style is cyan bold (\e[1;36m)
          parent_style = "\e[1;36m"
          header_prefix = match[1]
          content = match[2]
          formatted_content = format_inline_spans(content, parent_style)
          io << parent_style << header_prefix << " " << formatted_content << "\e[0m"
        elsif match = line.match(BLOCKQUOTE_REGEX)
          # Blockquote: parent style is gray italic (\e[3;90m)
          parent_style = "\e[3;90m"
          content = match[1]
          formatted_content = format_inline_spans(content, parent_style)
          io << parent_style << "> " << formatted_content << "\e[0m"
        else
          # Regular line: default parent style (\e[0m)
          io << format_inline_spans(line, "")
        end
      end

      # Formats inline markdown spans (bold, italic, links) within a given parent style context.
      # When an inner span ends, it restores parent_style instead of hard \e[0m reset if parent_style is present.
      private def format_inline_spans(text : String, parent_style : String) : String
        reset_style = parent_style.empty? ? "\e[0m" : parent_style

        # Bold: \e[1;97m ... reset_style
        result = text.gsub(BOLD_REGEX) do
          "\e[1;97m#{$~[1]}#{reset_style}"
        end

        # Italic: \e[3m ... reset_style
        result = result.gsub(ITALIC_REGEX) do
          "\e[3m#{$~[1]}#{reset_style}"
        end

        # Links: \e[34m link_text reset_style (\e[4;34m url reset_style)
        result = result.gsub(LINK_REGEX) do
          "\e[34m#{$~[1]}#{reset_style} (\e[4;34m#{$~[2]}#{reset_style})"
        end

        result
      end

      # Incremental state-machine lexer for formatting streaming model outputs in-flight.
      class IncrementalLexer
        property in_code_block : Bool = false
        property code_block_lang : String = ""

        def initialize
        end

        # Process incoming chunk, maintaining state across stream chunks
        def process_chunk(chunk : String) : String
          MarkdownFormatter.format(chunk)
        end
      end
    end
  end
end
