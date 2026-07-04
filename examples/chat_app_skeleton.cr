require "salamander"
require "mantle"
require "colorize"

# ==============================================================================
# Salamander + Mantle Chat Application Skeleton
# ==============================================================================
# This is a skeleton demonstrating how to wire up the Salamander Yielding Sandbox
# with Mantle's ToolEnabledChatFlow to create a fully-featured terminal chat app.
# ==============================================================================

bot_name = "SkeletonBot"
icon = "🤖"

# 1. Initialize Mantle Components
# In a real app, these would be configured to point to your LLM API and context storage.
logger = Mantle::Support::FileLogger.new("logs/app.log")
client = Mantle::Clients::LlamaClient.new(host: "localhost", port: 8080)
context_manager = Mantle::Storage::ContextManager.new("context.json", "memory.json")
flow = Mantle::Flows::ToolEnabledChatFlow.new(context_manager, client, logger)

# 2. Start the Salamander UI Sandbox
Salamander::Terminal.run(bot_name: bot_name, icon: icon) do |ui|
  
  ui.print_separator
  puts "Welcome to the #{bot_name} Skeleton App!"
  puts "Type 'exit' to quit."
  
  # Create a ChatSession to manage streaming state (Evaluating -> Thinking -> Responding)
  session = Salamander::ChatSession.new(on_state_change: ->(state : Salamander::ChatSession::State) {
    case state
    when .thinking?
      ui.waybar.update(:thinking)
    when .responding?
      ui.waybar.update(:responding)
    end
  })
  
  # The Interactive Chat Loop
  loop do
    # Prompt user
    user_input = ui.ask_user("You: ")
    break if user_input.nil? || user_input.strip.empty? || user_input.strip.downcase == "exit"
    
    # Notify system status
    ui.waybar.update(:evaluating)
    print "◆ #{bot_name} ".colorize(:magenta).mode(:bold)
    
    # Spin while processing
    ui.spin_while("Loading / Working...", -> { 
      case session.state
      when .evaluating? then :evaluating
      when .thinking?   then :thinking
      when .responding? then :responding
      else                   :idle
      end
    }) do
      
      # Run the Mantle Flow
      flow.run(
        user_input,
        max_iterations: 10,
        
        # Stream chunks dynamically as the LLM generates them
        on_chunk: ->(chunk : String) {
          processed = session.process_chunk(chunk)
          
          # Erase the spinner as soon as the model starts responding
          if processed.state_changed && processed.state.responding?
            ui.clear_line
          end
          
          # Stream clean content to the terminal
          ui.stream_text(processed.content)
        },
        
        # Handle final completion
        on_response: ->(resp : Mantle::Clients::Response) {
          # Clean up any leftover artifacts and format the final markdown
          if content = resp.content
            ui.clear_and_reposition(content)
            puts "◆ #{bot_name} ".colorize(:magenta).mode(:bold)
            puts Mantle::Support::MarkdownFormatter.format(content)
          end
          puts
          STDOUT.flush
        }
      )
    end
    
    # Reset system status for the next interaction
    ui.waybar.update(:idle)
  end
  
  ui.print_separator
  puts "Goodbye!"
end
