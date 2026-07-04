# src/salamander/waybar.cr

require "colorize"

module Salamander
  # ==============================================================================
  # WAYBAR NOTIFIER - SYSTEM STATUS INTEGRATION
  # ==============================================================================
  class WaybarNotifier
    @status_channel : Channel(Symbol)
    @status_fiber : Fiber?
    @icon : String
    @status_file : String

    # Initialize Waybar integration
    # - icon: The icon used for desktop notifications
    # - status_file: Path to a file that waybar will read for status text
    def initialize(@icon : String, @status_file : String)
      @status_channel = Channel(Symbol).new(10)
      @status_fiber = nil
    end

    # Start the background status update worker
    def start
      # Ensure graceful exit on Ctrl+C or kill
      Signal::INT.trap do
        puts "\n\n[System] Gracefully shutting down...".colorize(:yellow)
        exit
      end
      Signal::TERM.trap do
        puts "\n\n[System] Gracefully shutting down...".colorize(:yellow)
        exit
      end

      # Write "Offline" status on exit
      at_exit do
        begin
          write_status("Offline")
          update_waybar
        rescue ex
          puts "Error writing offline status file: #{ex.message}"
        end
      end

      # Write initial "Idle" status
      write_status("Idle")

      # Start background worker
      @status_fiber = spawn do
        begin
          loop do
            flag = @status_channel.receive
            status_string = map_status_flag(flag)

            begin
              write_status(status_string)
              update_waybar
            rescue ex
              puts "Error writing status file: #{ex.message}"
            end
          end
        rescue ex
          puts "Status fiber crashed: #{ex.message}"
        end
      end
    end

    # Update the current status
    def update(flag : Symbol)
      @status_channel.send(flag)
    end

    # Send a desktop notification
    def notify(title : String, message : String)
      spawn do
        begin
          Process.run("notify-send", ["--icon=#{@icon}", "--", title, message])
        rescue ex
          puts "Failed to perform notify_send for message: #{message}"
        end
      end
    end

    private def map_status_flag(flag : Symbol) : String
      case flag
      when :online
        "Online"
      when :evaluating
        "Loading/Working"
      when :thinking
        "Thinking"
      when :responding
        "Responding"
      when :tool_loop
        "Tool Loop"
      when :idle
        "Idle"
      when :memory_consolidation
        "Consolidating"
      when :background_task
        "Busy (Background)"
      else
        flag.to_s.capitalize
      end
    end

    private def write_status(status : String)
      unless @status_file.empty?
        begin
          File.write(@status_file, status)
          File.chmod(@status_file, 0o600)
        rescue ex
          # ignore
        end
      end
    end

    private def update_waybar
      Process.run("pkill", ["-RTMIN+5", "waybar"])
    end
  end
end
