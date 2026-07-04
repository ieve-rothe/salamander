# src/salamander/terminal.cr

require "./ui"
require "./waybar"

module Salamander
  # The environment setup/teardown wrapper (Yielding Sandbox Pattern).
  module Terminal
    extend self

    # Starts the terminal environment, trapping signals, setting up waybar and TTS,
    # and yielding a clean `UI` toolbelt to the application.
    def run(
      bot_name : String,
      icon : String,
      voice_blend : String? = nil,
      speed : Float64 = 1.0,
      status_file : String = "",
      tts : TtsKokoro::TTS? = nil,
      &block : UI ->
    )
      waybar = WaybarNotifier.new(icon, status_file)
      waybar.start

      ui = UI.new(waybar, tts, voice_blend, speed)

      begin
        yield ui
      rescue ex
        waybar.notify("Error", "Terminal application crashed: #{ex.message}")
        raise ex
      ensure
        # Ensure cleanup
        waybar.update(:idle)
      end
    end
  end
end
