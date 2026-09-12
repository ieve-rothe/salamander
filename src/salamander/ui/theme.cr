# salamander/src/salamander/ui/theme.cr
# Copyright (C) 2026 Cam Carroll
# Licensed under the AGPL-3.0. See LICENSE for details.

class Salamander::UI
  enum BoxStyle
    Rounded
    Sharp
    Armored
  end

  # Pluggable terminal theme palette and typography system.
  # Supports TrueColor (24-bit) & 256-color fallbacks with curated hacker-chique palettes.
  module Theme
    extend self

    # Base Terminal ANSI Modifiers
    RESET         = "\e[0m"
    BOLD          = "\e[1m"
    DIM           = "\e[2m"
    ITALIC        = "\e[3m"
    UNDERLINE     = "\e[4m"

    # Legacy static constants for backwards-compatibility with existing tests and call sites
    BORDER        = "\e[38;5;240m" # Muted slate border
    BORDER_ACTIVE = "\e[38;5;67m"  # Steel blue border
    TITLE         = "\e[1;38;5;110m" # Crisp steel cyan title
    TITLE_ACTIVE  = "\e[1;38;5;141m" # Soft muted violet title
    USER_PROMPT   = "\e[1;38;5;255m" # Bright crisp white
    THOUGHT       = "\e[38;5;180m" # Subtle warm wheat
    FILENAME      = "\e[38;5;223m" # Soft warm cream
    SUCCESS_ICON  = "\e[38;5;114m" # Soft sage green
    META_DIM      = "\e[38;5;244m" # Subdued metadata gray
    TOKEN_BADGE   = "\e[38;5;147m" # Soft lavender token tag
    LINE_NO       = "\e[38;5;240m" # Subdued line number gutter
    CODE_TEXT     = "\e[38;5;252m" # Clean off-white code
    NOTICE_DIM    = "\e[3;38;5;243m" # Italic muted notice
    STATUS_TAG    = "\e[38;5;116m" # Soft aqua
    HIGHLIGHT     = "\e[38;5;215m" # Soft peach/amber accent

    abstract class BaseTheme
      abstract def name : String
      abstract def border : String
      abstract def border_active : String
      abstract def border_danger : String
      abstract def title : String
      abstract def title_active : String
      abstract def user_prompt : String
      abstract def prompt_glyph : String
      abstract def thought : String
      abstract def filename : String
      abstract def success_icon : String
      abstract def error_icon : String
      abstract def meta_dim : String
      abstract def token_badge : String
      abstract def line_no : String
      abstract def code_text : String
      abstract def code_bg : String
      abstract def notice_dim : String
      abstract def status_tag : String
      abstract def highlight : String
      abstract def box_style : Salamander::UI::BoxStyle

      def pill(key : String, label : String) : String
        "[#{key}] #{label}"
      end

      def bracket_tag(category : String, value : String, color : String? = nil) : String
        c = color || status_tag
        "#{meta_dim}[#{RESET}#{c}#{category}: #{value}#{RESET}#{meta_dim}]#{RESET}"
      end
    end

    # Classic original theme
    class ClassicTheme < BaseTheme
      def name : String; "classic"; end
      def border : String; "\e[38;5;240m"; end
      def border_active : String; "\e[38;5;67m"; end
      def border_danger : String; "\e[38;5;196m"; end
      def title : String; "\e[1;38;5;110m"; end
      def title_active : String; "\e[1;38;5;141m"; end
      def user_prompt : String; "\e[1;38;5;255m"; end
      def prompt_glyph : String; "> "; end
      def thought : String; "\e[38;5;180m"; end
      def filename : String; "\e[38;5;223m"; end
      def success_icon : String; "\e[38;5;114m"; end
      def error_icon : String; "\e[38;5;196m"; end
      def meta_dim : String; "\e[38;5;244m"; end
      def token_badge : String; "\e[38;5;147m"; end
      def line_no : String; "\e[38;5;240m"; end
      def code_text : String; "\e[38;5;252m"; end
      def code_bg : String; "\e[48;5;236m"; end
      def notice_dim : String; "\e[3;38;5;243m"; end
      def status_tag : String; "\e[38;5;116m"; end
      def highlight : String; "\e[38;5;215m"; end
      def box_style : Salamander::UI::BoxStyle; Salamander::UI::BoxStyle::Rounded; end

      def pill(key : String, label : String) : String
        "[#{key}] #{label}"
      end
    end

    # Neo-Tokyo Cyberpunk "Ghost Grid" Theme
    class CyberpunkTheme < BaseTheme
      def name : String; "cyberpunk"; end
      def border : String; "\e[38;2;48;61;84m"; end          # Slate Gunmetal Grid (#303D54)
      def border_active : String; "\e[1;38;2;0;229;255m"; end # Electric Cyan (#00E5FF)
      def border_danger : String; "\e[1;38;2;255;42;109m"; end # Laser Fuchsia (#FF2A6D)
      def title : String; "\e[1;38;2;102;240;255m"; end       # Cyan Glow (#66F0FF)
      def title_active : String; "\e[1;38;2;255;42;109m"; end  # Laser Fuchsia (#FF2A6D)
      def user_prompt : String; "\e[1;38;2;240;246;252m"; end  # Stark Snow (#F0F6FC)
      def prompt_glyph : String; "\e[1;38;2;0;229;255m❯❯\e[0m "; end
      def thought : String; "\e[3;38;2;110;175;195m"; end     # Phosphor Teal (#6EAFC3)
      def filename : String; "\e[1;38;2;102;240;255m"; end    # Electric Ice (#66F0FF)
      def success_icon : String; "\e[1;38;2;5;255;161m"; end  # Acid Lime (#05FFA1)
      def error_icon : String; "\e[1;38;2;255;42;109m"; end   # Laser Fuchsia
      def meta_dim : String; "\e[38;2;125;139;158m"; end      # Gunmetal Gray (#7D8B9E)
      def token_badge : String; "\e[38;2;189;0;255m"; end     # Tachyon Violet (#BD00FF)
      def line_no : String; "\e[38;2;74;85;104m"; end         # Gutter Slate (#4A5568)
      def code_text : String; "\e[38;2;240;246;252m"; end     # Stark Snow
      def code_bg : String; "\e[48;2;18;23;34m"; end          # Recessed Obsidian (#121722)
      def notice_dim : String; "\e[3;38;2;125;139;158m"; end
      def status_tag : String; "\e[38;2;0;229;255m"; end
      def highlight : String; "\e[1;38;2;255;190;11m"; end    # Solar Amber (#FFBE0B)
      def box_style : Salamander::UI::BoxStyle; Salamander::UI::BoxStyle::Sharp; end

      def pill(key : String, label : String) : String
        "\e[38;2;0;229;255m⟦\e[0m\e[1;38;2;255;190;11m#{key}\e[0m\e[38;2;0;229;255m⟧\e[0m \e[38;2;125;139;158m#{label}\e[0m"
      end

      def bracket_tag(category : String, value : String, color : String? = nil) : String
        c = color || "\e[38;2;0;229;255m"
        "\e[38;2;48;61;84m⟦\e[0m#{c}#{category}: #{value}\e[0m\e[38;2;48;61;84m⟧\e[0m"
      end
    end

    # Midnight Outrun Chique Theme
    class OutrunTheme < BaseTheme
      def name : String; "outrun"; end
      def border : String; "\e[38;2;68;71;90m"; end          # Dusk Slate (#44475A)
      def border_active : String; "\e[1;38;2;189;147;249m"; end # Electric Lavender (#BD93F9)
      def border_danger : String; "\e[1;38;2;255;85;85m"; end   # Sunset Rose (#FF5555)
      def title : String; "\e[1;38;2;189;147;249m"; end       # Electric Lavender (#BD93F9)
      def title_active : String; "\e[1;38;2;255;121;198m"; end # Sunset Coral (#FF79C6)
      def user_prompt : String; "\e[1;38;2;248;248;242m"; end # Diamond White (#F8F8F2)
      def prompt_glyph : String; "\e[1;38;2;255;121;198m❯\e[0m "; end # Coral Chevron
      def thought : String; "\e[3;38;2;202;169;224m"; end     # Ethereal Orchid (#CAA9E0)
      def filename : String; "\e[38;2;255;184;108m"; end      # Sunset Peach (#FFB86C)
      def success_icon : String; "\e[38;2;80;250;123m"; end   # Cyber Mint (#50FA7B)
      def error_icon : String; "\e[38;2;255;85;85m"; end      # Sunset Rose
      def meta_dim : String; "\e[38;2;98;114;164m"; end       # Twilight Steel (#6272A4)
      def token_badge : String; "\e[38;2;139;233;253m"; end   # Icy Cyan (#8BE9FD)
      def line_no : String; "\e[38;2;98;114;164m"; end        # Twilight Steel
      def code_text : String; "\e[38;2;248;248;242m"; end     # Off-white
      def code_bg : String; "\e[48;2;40;42;54m"; end          # Dark Velvet (#282A36)
      def notice_dim : String; "\e[3;38;2;98;114;164m"; end
      def status_tag : String; "\e[38;2;139;233;253m"; end
      def highlight : String; "\e[38;2;255;184;108m"; end     # Warm Peach
      def box_style : Salamander::UI::BoxStyle; Salamander::UI::BoxStyle::Rounded; end

      def pill(key : String, label : String) : String
        "\e[38;2;98;114;164m(\e[0m \e[1;38;2;255;121;198m[#{key}]\e[0m \e[38;2;189;147;249m#{label}\e[0m \e[38;2;98;114;164m)\e[0m"
      end

      def bracket_tag(category : String, value : String, color : String? = nil) : String
        c = color || "\e[38;2;139;233;253m"
        "\e[38;2;98;114;164m( · \e[0m#{c}#{category}: #{value}\e[0m\e[38;2;98;114;164m · )\e[0m"
      end
    end

    # Aegis Phosphor / Tactical DEFCON-1 Theme
    class PhosphorTheme < BaseTheme
      def name : String; "phosphor"; end
      def border : String; "\e[38;2;42;50;66m"; end           # Slate Matrix (#2A3242)
      def border_active : String; "\e[1;38;2;255;176;0m"; end # Phosphor Amber (#FFB000)
      def border_danger : String; "\e[1;38;2;255;51;68m"; end  # Signal Crimson (#FF3344)
      def title : String; "\e[1;38;2;255;176;0m"; end        # Phosphor Amber
      def title_active : String; "\e[1;38;2;0;255;102m"; end  # Phosphor Emerald (#00FF66)
      def user_prompt : String; "\e[1;38;2;247;250;252m"; end # Stark Alabaster (#F7FAFC)
      def prompt_glyph : String; "\e[1;38;2;255;176;0m▶\e[0m "; end # Heavy Amber Chevron
      def thought : String; "\e[3;38;2;217;155;38m"; end      # Amber Ochre (#D99B26)
      def filename : String; "\e[1;38;2;255;199;64m"; end     # Warm Gold (#FFC740)
      def success_icon : String; "\e[1;38;2;0;255;102m"; end  # Phosphor Emerald (#00FF66)
      def error_icon : String; "\e[1;38;2;255;51;68m"; end   # Signal Crimson
      def meta_dim : String; "\e[38;2;121;136;163m"; end      # Telemetry Gray (#7988A3)
      def token_badge : String; "\e[38;2;0;212;255m"; end     # Cyan Meter (#00D4FF)
      def line_no : String; "\e[38;2;77;91;112m"; end         # Gutter Slate (#4D5B70)
      def code_text : String; "\e[38;2;214;222;235m"; end     # Ice White Payload
      def code_bg : String; "\e[48;2;30;37;48m"; end          # Charcoal Matrix (#1E2530)
      def notice_dim : String; "\e[3;38;2;121;136;163m"; end
      def status_tag : String; "\e[1;38;2;0;255;102m"; end
      def highlight : String; "\e[1;38;2;255;176;0m"; end
      def box_style : Salamander::UI::BoxStyle; Salamander::UI::BoxStyle::Sharp; end

      def pill(key : String, label : String) : String
        "\e[38;2;18;22;31;48;2;0;255;102;1m #{key} \e[0m \e[38;2;121;136;163m#{label}\e[0m"
      end

      def bracket_tag(category : String, value : String, color : String? = nil) : String
        c = color || "\e[1;38;2;0;255;102m"
        "\e[38;2;121;136;163m[\e[0m#{c}#{category}: #{value}\e[0m\e[38;2;121;136;163m]\e[0m"
      end
    end

    @@current : BaseTheme = CyberpunkTheme.new

    def current : BaseTheme
      @@current
    end

    def current=(theme : BaseTheme)
      @@current = theme
    end

    def all_names : Array(String)
      ["cyberpunk", "outrun", "phosphor", "classic"]
    end

    def set_theme(name : String) : BaseTheme
      case name.downcase.strip
      when "cyberpunk"
        @@current = CyberpunkTheme.new
      when "outrun"
        @@current = OutrunTheme.new
      when "phosphor"
        @@current = PhosphorTheme.new
      when "classic"
        @@current = ClassicTheme.new
      else
        raise ArgumentError.new("Unknown theme: '#{name}'. Available: #{all_names.join(", ")}")
      end
    end

    # Dynamic delegators to current theme
    def border; @@current.border; end
    def border_active; @@current.border_active; end
    def border_danger; @@current.border_danger; end
    def title; @@current.title; end
    def title_active; @@current.title_active; end
    def user_prompt; @@current.user_prompt; end
    def prompt_glyph; @@current.prompt_glyph; end
    def thought; @@current.thought; end
    def filename; @@current.filename; end
    def success_icon; @@current.success_icon; end
    def error_icon; @@current.error_icon; end
    def meta_dim; @@current.meta_dim; end
    def token_badge; @@current.token_badge; end
    def line_no; @@current.line_no; end
    def code_text; @@current.code_text; end
    def code_bg; @@current.code_bg; end
    def notice_dim; @@current.notice_dim; end
    def status_tag; @@current.status_tag; end
    def highlight; @@current.highlight; end
    def box_style; @@current.box_style; end
    def pill(key : String, label : String); @@current.pill(key, label); end
    def bracket_tag(category : String, value : String, color : String? = nil)
      @@current.bracket_tag(category, value, color)
    end
  end
end
