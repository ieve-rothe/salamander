require "./spec_helper"

describe Salamander::UI do
  it "starts and stops spinner tracking spinning? state" do
    waybar = Salamander::WaybarNotifier.new("🐾", "")
    ui = Salamander::UI.new(waybar)

    ui.spinning?.should be_false

    ui.start_spinner("Testing...")
    ui.spinning?.should be_true

    ui.stop_spinner
    ui.spinning?.should be_false
  end

  it "stops spinner when state transitions to :responding" do
    waybar = Salamander::WaybarNotifier.new("🐾", "")
    ui = Salamander::UI.new(waybar)

    current_state = :evaluating
    state_getter = -> { current_state }

    ui.start_spinner("Testing...", state_getter)
    ui.spinning?.should be_true

    # Transition state to :responding
    current_state = :responding
    sleep 100.milliseconds

    ui.spinning?.should be_false
  end

  it "computes terminal width and physical line counts" do
    Salamander::UI.terminal_width.should be > 0
    Salamander::UI.count_physical_lines("hello").should eq(1)
    Salamander::UI.count_physical_lines("hello\nworld").should eq(2)
    Salamander::UI.count_physical_lines("hello\nworld\n").should eq(3)
  end

  it "handles clear_and_reposition without raising" do
    Salamander::UI.clear_and_reposition("Testing clear line\n")
  end
end
