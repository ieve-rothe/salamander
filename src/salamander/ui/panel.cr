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

    def initialize(@width : Int32)
      @width = Math.max(20, @width)
    end

    # Clamps terminal width to a readable max width (default 105) on ultra-wide screens
    def self.clamp_width(term_width : Int32, max_width : Int32 = 105, padding : Int32 = 4) : Int32
      Math.min(term_width - padding, max_width)
    end

    # Renders the top border of the panel with a title and optional right-aligned badge
    def render_header(title : String, badge : String? = nil, border_color : String = Theme::BORDER) : String
      inner_w = @width - 4
      raw_title_len = strip_ansi(title).size
      raw_badge_len = badge ? strip_ansi(badge).size + 1 : 0
      rem = Math.max(0, inner_w - raw_title_len - raw_badge_len)

      if badge
        "#{border_color}╭─#{Theme::RESET} #{title} #{border_color}#{"─" * rem}#{Theme::RESET} #{badge} #{border_color}╮#{Theme::RESET}"
      else
        "#{border_color}╭─#{Theme::RESET} #{title} #{border_color}#{"─" * rem}╮#{Theme::RESET}"
      end
    end

    # Renders a padded content row bounded by left and right borders
    def render_row(content : String, border_color : String = Theme::BORDER) : String
      inner_w = @width - 4
      raw_len = strip_ansi(content).size
      pad = Math.max(0, inner_w - raw_len)
      "#{border_color}│#{Theme::RESET} #{content}#{" " * pad}#{border_color}│#{Theme::RESET}"
    end

    # Renders a horizontal divider within the panel
    def render_divider(border_color : String = Theme::BORDER) : String
      inner_w = @width - 4
      "#{border_color}├#{"─" * (inner_w + 2)}┤#{Theme::RESET}"
    end

    # Renders the bottom closing border of the panel
    def render_footer(border_color : String = Theme::BORDER) : String
      inner_w = @width - 4
      "#{border_color}╰#{"─" * (inner_w + 2)}╯#{Theme::RESET}"
    end

    # Strips ANSI escape sequences to compute exact visual column widths
    def strip_ansi(str : String) : String
      self.class.strip_ansi(str)
    end

    def self.strip_ansi(str : String) : String
      str.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
    end
  end
end
