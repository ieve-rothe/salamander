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

  it "respects COLUMNS and LINES environment variables" do
    orig_cols = ENV["COLUMNS"]?
    orig_lines = ENV["LINES"]?
    begin
      ENV["COLUMNS"] = "42"
      ENV["LINES"] = "19"
      Salamander::UI.terminal_width.should eq(42)
      Salamander::UI.terminal_height.should eq(19)
    ensure
      if orig_cols
        ENV["COLUMNS"] = orig_cols
      else
        ENV.delete("COLUMNS")
      end
      if orig_lines
        ENV["LINES"] = orig_lines
      else
        ENV.delete("LINES")
      end
    end
  end

  it "handles clear_and_reposition without raising" do
    Salamander::UI.clear_and_reposition("Testing clear line\n")
  end

  it "does not emit cursor up escape code for single-line text" do
    io = IO::Memory.new
    Salamander::UI.clear_and_reposition("Appreciate it. Ready for the next bead whenever you are.", io)
    io.to_s.should eq("\r\e[J")
    io.to_s.should_not contain("\e[0A")
    io.to_s.should_not contain("\e[A")
  end

  it "emits cursor up escape code for multi-line text" do
    io = IO::Memory.new
    Salamander::UI.clear_and_reposition("Line 1\nLine 2\n", io)
    io.to_s.should eq("\r\e[2A\e[J")
  end
end
