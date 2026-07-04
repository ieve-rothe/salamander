# src/salamander/menu.cr

require "colorize"

module Salamander
  # Interactive terminal-based UI for selection.
  module Menu
    extend self

    # Represents an option in the menu
    struct Option
      property id : String
      property title : String
      property description : String?
      property tags : Array(String)

      def initialize(@id, @title, @description = nil, @tags = [] of String)
      end
    end

    # Displays an interactive selection menu.
    # Returns the selected option ID, or nil if exited.
    def choose(header : String, options : Array(Option)) : String?
      if options.empty?
        puts "[Error] No options available to select.".colorize(:red)
        return nil
      end

      puts
      if STDOUT.tty?
        width = header.size + 4
        width = width < 40 ? 40 : width
        puts "╔#{"═" * width}╗".colorize(:cyan)
        puts "║  #{header.center(width - 4)}  ║".colorize(:cyan)
        puts "╚#{"═" * width}╝".colorize(:cyan)
      else
        puts "--- #{header} ---"
      end
      puts

      # Display each option
      options.each_with_index do |opt, idx|
        puts "  #{(idx + 1).to_s.rjust(2)}) #{opt.id.colorize(:yellow)}"
        puts "      #{opt.title.colorize(:green)}"
        if desc = opt.description
          puts "      #{desc}"
        end
        unless opt.tags.empty?
          puts "      [#{opt.tags.join(", ").colorize(:dark_gray)}]"
        end
        puts
      end

      puts "   0) Exit".colorize(:dark_gray)
      puts
      print "Select an option (1-#{options.size}): ".colorize(:cyan).mode(:bold)

      input = gets
      return nil if input.nil?

      choice = input.strip.to_i?

      if choice == 0
        return nil
      elsif !choice.nil? && choice > 0 && choice <= options.size
        options[choice - 1].id
      else
        puts "[Error] Invalid selection. Please choose a number between 1 and #{options.size}".colorize(:red)
        puts
        choose(header, options) # Recursive retry
      end
    end
  end
end
