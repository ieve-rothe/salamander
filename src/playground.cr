require "./salamander"

puts "Starting Salamander Playground..."

# Let's write to a temp status file for the playground demo
status_file = File.tempname("salamander_playground_status", ".txt")
puts "Temp status file created at: #{status_file}"

Salamander::Terminal.run(
  bot_name: "PlaygroundBot",
  icon: "⚙️",
  status_file: status_file
) do |ui|
  
  ui.print_separator
  puts "1. Separator rendered above."
  
  # Demo 2: Menu selection
  puts "\n2. Testing Menu:"
  options = [
    Salamander::Menu::Option.new("option_1", "Option One", "First test option", ["tag1", "tag2"]),
    Salamander::Menu::Option.new("option_2", "Option Two", "Second test option", ["tag3"]),
  ]
  choice = ui.menu.choose("Choose an Option", options)
  puts "Selected: #{choice.inspect}"
  
  # Demo 3: Ask user
  puts "\n3. Testing User Prompt:"
  user_response = ui.ask_user("Enter some text: ")
  puts "User entered: #{user_response.inspect}"
  
  # Demo 4: Spinner and state transitions
  puts "\n4. Testing Spinner & Waybar state updates (will transition Evaluating -> Thinking -> Responding):"
  state = :evaluating
  ui.spin_while("Evaluating something...", -> { state }) do
    sleep 1.seconds
    state = :thinking
    sleep 1.seconds
    state = :responding
    ui.clear_line
    ui.stream_text("Streaming response text chunk 1... ")
    sleep 0.5.seconds
    ui.stream_text("chunk 2... done.\n")
  end
  
  # Demo 5: Desktop notifications
  puts "\n5. Triggering desktop notification via Waybar notifier..."
  ui.waybar.notify("Salamander Playground", "Testing notification system!")
  
  puts "\nPlayground complete! Cleaning up status file: #{status_file}"
  File.delete(status_file) if File.exists?(status_file)
end
