require "salamander"
require "mantle"
require "colorize"

# ==============================================================================
# Salamander + Mantle Chat Application Skeleton
# ==============================================================================
# This is a skeleton demonstrating how to wire up the Salamander Yielding Sandbox
# with Mantle's Session & Step pipeline to create a fully-featured terminal chat app.
# ==============================================================================

bot_name = "SkeletonBot"
icon = "🤖"

# 1. Initialize Mantle Components
# In a real app, these would be configured to point to your LLM API and context storage.
model_config = Mantle::Clients::ModelConfig.new(
  model_name: "llama3",
  stream: true,
  temperature: 0.7,
  top_p: 0.9,
  max_tokens: 2048,
  api_url: "http://localhost:11434/api/chat"
)
client = Mantle::Clients::OllamaClient.new(model_config)
context_store = Mantle::Storage::JSONContextStore.new("context.json", "You are #{bot_name}, a helpful assistant.")
memory_store = Mantle::Storage::JSONLayeredMemoryStore.new(
  memory_file: "memory.json",
  layer_token_capacity: 4000,
  layer_token_target: 2000,
  squishifier: ->(messages : Array(String)) { messages.join("\n") }
)
context_manager = Mantle::Storage::ContextManager.new(
  context_store: context_store,
  memory_store: memory_store,
  user_name: "User",
  bot_name: bot_name,
  strip_thinking_tags: true
)
step = Mantle::Step.new(client: client, max_iterations: 10)
session = Mantle::Session.new(context_manager, step, log_file: "logs/session.jsonl")

# 2. Start the Salamander UI Sandbox
Salamander::Terminal.run(bot_name: bot_name, icon: icon) do |ui|
  ui.print_separator
  puts "Welcome to the #{bot_name} Skeleton App!"
  puts "Type 'exit' to quit."

  # Create a ChatSession to manage streaming state (Evaluating -> Thinking -> Responding)
  chat_session = Salamander::ChatSession.new(on_state_change: ->(state : Salamander::ChatSession::State) {
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
    ui.spin_while("Loading / Working...", ->{
      case chat_session.state
      when .evaluating? then :evaluating
      when .thinking?   then :thinking
      when .responding? then :responding
      else                   :idle
      end
    }) do
      # Run the Mantle Session Turn with streaming chunk support
      result = session.run_turn(user_input) do |chunk|
        processed = chat_session.process_chunk(chunk)

        # Erase the spinner as soon as the model starts responding
        if processed.state_changed && processed.state.responding?
          ui.clear_line
        end

        # Stream clean content to the terminal
        ui.stream_text(processed.content)
      end

      # Handle completion
      if content = result.value
        ui.clear_and_reposition(content)
        puts "◆ #{bot_name} ".colorize(:magenta).mode(:bold)
        puts Salamander::UI::MarkdownFormatter.format(content)
      elsif err = result.error
        puts "\n[Error] #{err}".colorize(:red)
      end
      puts
      STDOUT.flush
    end

    # Reset system status for the next interaction
    ui.waybar.update(:idle)
  end

  ui.print_separator
  puts "Goodbye!"
end
