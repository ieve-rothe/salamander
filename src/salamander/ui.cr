# src/salamander/ui.cr

require "colorize"
require "tts_kokoro"
require "./waybar"
require "./menu"
require "./ui/theme"
require "./ui/panel"
require "./ui/code_preview"
require "./ui/editor"

module Salamander
  # The UI Toolbelt. Provides methods to interact with the user via terminal and TTS.
  class UI
    @waybar : WaybarNotifier
    @tts : TtsKokoro::TTS?
    @voice_blend : String?
    @speed : Float64?
    
    @spinner_fiber : Fiber?
    @stop_channel : Channel(Nil)?
    getter? spinning : Bool

    @@current : UI?
    
    def self.current : UI?
      @@current
    end

    getter waybar

    def initialize(@waybar : WaybarNotifier, @tts : TtsKokoro::TTS? = nil, @voice_blend : String? = nil, @speed : Float64? = 1.0)
      @spinner_fiber = nil
      @stop_channel = nil
      @spinning = false
      @@current = self
    end

    # Ask the user for input with a prompt.
    def ask_user(prompt : String) : String?
      puts
      print prompt.colorize(:cyan).mode(:bold)
      input = gets
      sleep(0.1.seconds)
      input.try(&.strip)
    end

    # Output content to the terminal and TTS if available.
    def stream_text(chunk : String, tts_buffer : TtsKokoro::StreamingTTSBuffer? = nil)
      unless chunk.empty?
        print chunk
        STDOUT.flush
        tts_buffer.try(&.push(chunk))
      end
    end

    # Print a distinct separator line
    def print_separator
      if STDOUT.tty?
        top_bar = "═" * (terminal_width - 2)
        puts "╔#{top_bar}╗"
      else
        puts "---"
      end
    end

    # Wrapper to animate a spinner while a block executes
    def spin_while(message : String, state_getter : Proc(Symbol)? = nil, &block)
      start_spinner(message, state_getter)
      begin
        yield
      ensure
        stop_spinner
      end
    end

    # Access the menu system
    def menu
      Salamander::Menu
    end

    # Create a TTS buffer for a response stream
    def create_tts_buffer : TtsKokoro::StreamingTTSBuffer?
      if tts = @tts
        buffer = TtsKokoro::StreamingTTSBuffer.new(
          tts,
          voice_blend: @voice_blend || "af_bella",
          speed: @speed || 1.0
        )
        buffer.start
        buffer
      else
        nil
      end
    end

    # Low level spinner control
    def start_spinner(default_message : String, state_getter : Proc(Symbol)? = nil)
      @stop_channel = Channel(Nil).new(1)
      stop_chan = @stop_channel.not_nil!
      @spinning = true

      @spinner_fiber = spawn do
        begin
          spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
          spinner_idx = 0
          last_state = nil

          loop do
            break unless @spinning

            select
            when stop_chan.receive
              break
            when timeout(80.milliseconds)
            end

            break unless @spinning

            current_state = state_getter ? state_getter.call : :evaluating
            break if current_state == :responding

            msg, color = case current_state
                         when :evaluating
                           {default_message, :cyan}
                         when :thinking
                           {"Thinking...", :magenta}
                         else
                           {default_message, :dark_gray}
                         end

            if STDOUT.tty?
              print "\r#{msg.colorize(color)} #{spinner_chars[spinner_idx].to_s.colorize(color)} "
              STDOUT.flush
              spinner_idx = (spinner_idx + 1) % spinner_chars.size
            else
              if current_state != last_state
                puts msg.colorize(color)
                STDOUT.flush
                last_state = current_state
              end
            end
          end
        rescue ex
          puts "UI spinner crashed: #{ex.message}"
        ensure
          @spinning = false
        end
      end
      sleep 10.milliseconds
    end

    def stop_spinner
      @spinning = false
      if stop_chan = @stop_channel
        @stop_channel = nil
        select
        when stop_chan.send(nil)
        else
        end
      end
    end

    def clear_line
      if STDOUT.tty?
        print "\e[2K\r"
        STDOUT.flush
      end
    end

    def clear_and_reposition(text : String, io : IO = STDOUT)
      UI.clear_and_reposition(text, io)
    end

    def self.clear_and_reposition(text : String, io : IO = STDOUT)
      is_tty = io.responds_to?(:tty?) && io.tty?
      if is_tty || io.is_a?(IO::Memory)
        lines_to_clear = count_physical_lines(text)
        up_moves = [0, lines_to_clear - 1].max
        if up_moves > 0
          io.print "\r\e[#{up_moves}A\e[J"
        else
          io.print "\r\e[J"
        end
        io.flush
      end
    end

    def render_separator(label : String? = nil, width : Int32? = nil) : String
      UI.render_separator(label, width)
    end

    def self.render_separator(label : String? = nil, width : Int32? = nil) : String
      term_w = terminal_width
      w = width || Panel.clamp_width(term_w)
      border_color = Theme.border
      reset = Theme::RESET

      if label && !label.empty?
        tag = "#{Theme.status_tag}#{label}#{reset}"
        prefix = "─── "
        prefix_vis_w = Panel.visual_width(prefix)
        label_vis_w = Panel.visual_width(label)
        rem = Math.max(0, w - prefix_vis_w - label_vis_w - 1)
        "#{border_color}#{prefix}#{tag} #{border_color}#{"─" * rem}#{reset}"
      else
        "#{border_color}#{"─" * w}#{reset}"
      end
    end

    # C bindings for terminal size detection and Unicode display width
    lib LibTerminal
      {% if flag?(:linux) %}
        TIOCGWINSZ = 0x5413u32
      {% elsif flag?(:darwin) || flag?(:bsd) %}
        TIOCGWINSZ = 0x40087468u32
      {% end %}

      struct Winsize
        ws_row : UInt16
        ws_col : UInt16
        ws_xpixel : UInt16
        ws_ypixel : UInt16
      end

      fun ioctl(fd : LibC::Int, request : LibC::ULong, ...) : LibC::Int
      fun setlocale(category : LibC::Int, locale : UInt8*) : UInt8*
      fun wcwidth(c : LibC::Int) : LibC::Int
    end

    @@locale_initialized = false

    def self.init_locale : Nil
      return if @@locale_initialized
      LibTerminal.setlocale(0, "") # LC_ALL
      @@locale_initialized = true
    end

    def self.char_width(char : Char) : Int32
      init_locale
      ord = char.ord
      return 0 if ord < 32 || (ord >= 0x7F && ord < 0xA0)
      w = LibTerminal.wcwidth(ord)
      w < 0 ? 1 : w
    end

    def terminal_width : Int32
      UI.terminal_width
    end

    def self.terminal_width : Int32
      if env_cols = ENV["COLUMNS"]?.try(&.to_i?)
        return env_cols if env_cols > 0
      end

      ws = LibTerminal::Winsize.new
      [1, 0, 2].each do |fd|
        if LibTerminal.ioctl(fd, LibTerminal::TIOCGWINSZ, pointerof(ws)) == 0 && ws.ws_col > 0
          return ws.ws_col.to_i
        end
      end

      80
    end

    def terminal_height : Int32
      UI.terminal_height
    end

    def self.terminal_height : Int32
      if env_lines = ENV["LINES"]?.try(&.to_i?)
        return env_lines if env_lines > 0
      end

      ws = LibTerminal::Winsize.new
      [1, 0, 2].each do |fd|
        if LibTerminal.ioctl(fd, LibTerminal::TIOCGWINSZ, pointerof(ws)) == 0 && ws.ws_row > 0
          return ws.ws_row.to_i
        end
      end

      24
    end

    def clear_screen
      UI.clear_screen
    end

    def self.clear_screen
      if STDOUT.tty?
        print "\e[H\e[2J"
        STDOUT.flush
      end
    end

    def count_physical_lines(text : String) : Int32
      UI.count_physical_lines(text)
    end

    def self.count_physical_lines(text : String) : Int32
      term_width = terminal_width
      lines = text.each_line.sum do |line|
        [1, (line.size.to_f / term_width).ceil.to_i].max
      end
      lines += 1 if text.ends_with?('\n')
      lines
    end
  end
end
