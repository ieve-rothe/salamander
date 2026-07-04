# src/salamander/ui.cr

require "colorize"
require "tts_kokoro"
require "./waybar"
require "./menu"

module Salamander
  # The UI Toolbelt. Provides methods to interact with the user via terminal and TTS.
  class UI
    @waybar : WaybarNotifier
    @tts : TtsKokoro::TTS?
    @voice_blend : String?
    @speed : Float64?
    
    @spinner_fiber : Fiber?
    @stop_channel : Channel(Nil)?

    @@current : UI?
    
    def self.current : UI?
      @@current
    end

    getter waybar

    def initialize(@waybar : WaybarNotifier, @tts : TtsKokoro::TTS? = nil, @voice_blend : String? = nil, @speed : Float64? = 1.0)
      @spinner_fiber = nil
      @stop_channel = nil
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

      @spinner_fiber = spawn do
        begin
          spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
          spinner_idx = 0
          last_state = nil

          loop do
            select
            when stop_chan.receive
              break
            when timeout(80.milliseconds)
            end

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
        end
      end
      sleep 10.milliseconds
    end

    def stop_spinner
      if stop_chan = @stop_channel
        spawn do
          begin
            stop_chan.send(nil)
          rescue ex
          end
        end
        @stop_channel = nil
      end
    end

    def clear_line
      if STDOUT.tty?
        print "\e[2K\r"
        STDOUT.flush
      end
    end

    def clear_and_reposition(text : String)
      if STDOUT.tty?
        lines_to_clear = count_physical_lines(text)
        up_moves = [0, lines_to_clear - 1].max
        print "\r\e[#{up_moves}A\e[J"
        STDOUT.flush
      end
    end

    # C bindings for terminal size detection
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
    end

    def terminal_width : Int32
      ws = LibTerminal::Winsize.new
      if LibTerminal.ioctl(1, LibTerminal::TIOCGWINSZ, pointerof(ws)) == 0
        ws.ws_col.to_i
      else
        80
      end
    end

    def count_physical_lines(text : String) : Int32
      term_width = terminal_width
      text.each_line.sum do |line|
        [1, (line.size.to_f / term_width).ceil.to_i].max
      end
    end
  end
end
