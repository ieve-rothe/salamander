# salamander/src/salamander/ui/theme.cr
# Copyright (C) 2026 Cam Carroll
# Licensed under the AGPL-3.0. See LICENSE for details.

class Salamander::UI
  # Curated 256/truecolor-safe terminal theme palette
  # Designed for crisp, professional developer CLI tooling
  module Theme
    extend self

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
    RESET         = "\e[0m"
  end
end
