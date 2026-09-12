# salamander/src/salamander/ui/code_preview.cr
# Copyright (C) 2026 Cam Carroll
# Licensed under the AGPL-3.0. See LICENSE for details.

require "./theme"
require "./panel"

class Salamander::UI
  # Formats a slice of code lines into a bordered panel with line number gutters,
  # syntax contrast, and truncation indicators.
  module CodePreview
    extend self

    def render(
      lines : Array(String),
      start_offset : Int32,
      max_preview_lines : Int32,
      panel : Panel,
      border_color : String = Theme::BORDER
    ) : Array(String)
      out = [] of String
      total = lines.size
      slice = lines[0...Math.min(max_preview_lines, total)]
      inner_w = panel.width - 4

      slice.each_with_index do |l, idx|
        lnum = (start_offset + idx).to_s.rjust(4)
        gutter = "#{lnum} │ "
        avail_code_w = Math.max(10, inner_w - gutter.size)
        code_str = l
        if code_str.size > avail_code_w
          code_str = code_str[0...Math.max(0, avail_code_w - 3)] + "..."
        end

        formatted = "#{Theme::LINE_NO}#{lnum} │#{Theme::RESET} #{Theme::CODE_TEXT}#{code_str}#{Theme::RESET}"
        out << panel.render_row(formatted, border_color)
      end

      if total > slice.size
        remaining = total - slice.size
        msg = if inner_w >= 65
          "#{Theme::NOTICE_DIM}... [#{remaining} more lines hidden; focus centered on active snippet] ...#{Theme::RESET}"
        elsif inner_w >= 40
          "#{Theme::NOTICE_DIM}... [#{remaining} more lines hidden] ...#{Theme::RESET}"
        else
          "#{Theme::NOTICE_DIM}... [+#{remaining} lines] ...#{Theme::RESET}"
        end
        out << panel.render_row(msg, border_color)
      end

      out
    end
  end
end
