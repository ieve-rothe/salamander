# Salamander 🦎

Salamander is a visual, interactive, and desktop notification UI subframework for building LLM applications using the [Mantle](https://github.com/ieve-rothe/mantle) framework.

It extracts the complex UI handling—such as terminal dimension calculations, ANSI escape sequences, animated spinners, Waybar system integrations, and TTS buffering—into a reusable library.

## The Yielding Sandbox Pattern

Salamander is designed around the **Yielding Sandbox Pattern**. 

Instead of Salamander owning your application's `while` loop or control flow, it acts as a structural wrapper. It handles the dirty environment setup and teardown (trapping `Ctrl+C`, initializing the Waybar socket, clearing the terminal, or setting up the audio buffer), and then yields a clean `UI` toolbelt object back to your application block.

Your application retains 100% control over the flow.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  salamander:
    path: ../salamander # Or github link once published
```

## Quickstart Guide

Here is a minimal example of how to wrap your application logic using `Salamander::Terminal.run` and utilize the `ui` toolbelt:

```crystal
require "salamander"

# Salamander sets up the terminal, Waybar, and TTS, then yields control.
Salamander::Terminal.run(bot_name: "Emma", icon: "🐾") do |ui|
  
  ui.print_separator
  
  # The Application dictates the actual flow.
  # For a chat app, you write the interactive loop here:
  loop do
    user_input = ui.ask_user("You: ")
    break unless user_input
    
    ui.waybar.update(:thinking)
    
    ui.spin_while("Mantle is generating...") do
      # Integrate Mantle here!
      # result = session.run_turn(user_input) do |chunk|
      #   ui.stream_text(chunk)
      # end

      # Simulate delay
      sleep 2.seconds

      ui.clear_line
      ui.stream_text("Response from Mantle goes here.\n")
    end
    
    ui.waybar.update(:idle)
  end

end
```

## UI Toolbelt Methods

The `ui` object yielded by the sandbox provides the following methods:

- `ui.ask_user(prompt : String)`: Safely prompts the user for CLI input.
- `ui.spin_while(message : String, state_getter : Proc(Symbol)?, &block)`: Wraps a block in an animated spinner. The spinner automatically stops when the block completes or when the `state_getter` transitions to `:responding`.
- `ui.stream_text(chunk : String, tts_buffer = nil)`: Streams text to the terminal and automatically feeds the TTS buffer if provided.
- `ui.clear_line`: Erases the current terminal line (useful for clearing the spinner before streaming).
- `ui.print_separator`: Prints a full-width boxed separator `╔═════╗`.
- `ui.waybar`: Accesses the `WaybarNotifier` to send status updates (`ui.waybar.update(:thinking)`) or desktop notifications (`ui.waybar.notify("Title", "Message")`).
- `ui.menu`: Accesses the interactive generic terminal chooser (`Salamander::Menu.choose`).

## Included Showcase

You can test all the interface elements provided by Salamander by running the included playground script:

```bash
crystal run src/playground.cr
```
