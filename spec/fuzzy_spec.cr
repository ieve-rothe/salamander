# spec/fuzzy_spec.cr
require "./spec_helper"

describe Salamander::Fuzzy do
  describe ".distance" do
    it "returns 0 for identical strings" do
      Salamander::Fuzzy.distance("hello", "hello").should eq(0)
      Salamander::Fuzzy.distance("", "").should eq(0)
    end

    it "handles empty string comparisons" do
      Salamander::Fuzzy.distance("", "test").should eq(4)
      Salamander::Fuzzy.distance("test", "").should eq(4)
    end

    it "calculates single character insertions, deletions, and substitutions" do
      Salamander::Fuzzy.distance("cat", "cats").should eq(1)
      Salamander::Fuzzy.distance("cats", "cat").should eq(1)
      Salamander::Fuzzy.distance("cat", "bat").should eq(1)
    end

    it "calculates multi-character edits" do
      Salamander::Fuzzy.distance("kitten", "sitting").should eq(3)
    end
  end

  describe ".similarity" do
    it "returns 1.0 for exact matches ignoring leading slash" do
      Salamander::Fuzzy.similarity("/model", "/model").should eq(1.0)
      Salamander::Fuzzy.similarity("model", "/model").should eq(1.0)
      Salamander::Fuzzy.similarity("/MODEL", "model").should eq(1.0)
    end

    it "awards substring and token bonuses for related commands" do
      # /last_context to /print_context (TKT-048 target case)
      score = Salamander::Fuzzy.similarity("/last_context", "/print_context")
      score.should be >= 0.4

      # /thnk to /thinking
      thnk_score = Salamander::Fuzzy.similarity("/thnk", "/thinking")
      thnk_score.should be >= 0.4
    end

    it "returns 0.0 for unrelated commands" do
      Salamander::Fuzzy.similarity("/xyz_nonsense", "/model").should eq(0.0)
      Salamander::Fuzzy.similarity("/foobar", "/clear").should eq(0.0)
    end
  end

  describe ".find_closest" do
    commands = [
      "/print_context", "/thinking", "/context_stats", "/beads", "/string", "/drives",
      "/router_stats", "/help", "/clear", "/clear_context",
      "/edit_bot", "/edit_response", "/edit_user", "/replay",
      "/paste", "/nudge", "/frame", "/switch_frame", "/limit", "/dream", "/dream_undo", "/exit",
      "/model", "/skill", "/plan", "/mode", "/theme", "/allowlist",
    ]

    it "suggests /print_context for /last_context" do
      Salamander::Fuzzy.find_closest("/last_context", commands).should eq("/print_context")
    end

    it "suggests /thinking for /thnk and /thinkingg" do
      Salamander::Fuzzy.find_closest("/thnk", commands).should eq("/thinking")
      Salamander::Fuzzy.find_closest("/thinkingg", commands).should eq("/thinking")
    end

    it "suggests /model for /modle and /mdl" do
      Salamander::Fuzzy.find_closest("/modle", commands).should eq("/model")
    end

    it "suggests /clear for /clearr" do
      Salamander::Fuzzy.find_closest("/clearr", commands).should eq("/clear")
    end

    it "suggests /allowlist for /alowlst" do
      Salamander::Fuzzy.find_closest("/alowlst", commands).should eq("/allowlist")
    end

    it "returns nil for completely unrecognized inputs" do
      Salamander::Fuzzy.find_closest("/unmatched_slash_xyz", commands).should be_nil
      Salamander::Fuzzy.find_closest("/qwertyuiop", commands).should be_nil
    end
  end

  describe ".find_top" do
    commands = ["/clear", "/clear_context", "/theme"]

    it "returns ranked top candidates" do
      matches = Salamander::Fuzzy.find_top("/clr", commands, limit: 2)
      matches.should_not be_empty
      matches.first[0].should eq("/clear")
    end
  end

  describe ".did_you_mean" do
    commands = ["/model", "/mode", "/thinking"]

    it "formats suggestion string" do
      suggestion = Salamander::Fuzzy.did_you_mean("/modle", commands)
      suggestion.should_not be_nil
      suggestion.not_nil!.should contain("model")
    end

    it "returns nil when no match meets threshold" do
      Salamander::Fuzzy.did_you_mean("/unknown_xyz", commands).should be_nil
    end
  end

  describe ".choose_action" do
    it "handles option 1 (Execute suggested command)" do
      stdin = IO::Memory.new("1\n")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      action, payload = Salamander::Fuzzy.choose_action(
        "/last_context",
        "/print_context",
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      action.should eq(Salamander::Fuzzy::Action::Execute)
      payload.should eq("/print_context")
      stderr.to_s.should contain("Unknown command '/last_context'")
      stderr.to_s.should contain("Did you mean")
      stdout.to_s.should contain("1. Execute '/print_context'")
    end

    it "handles option 2 (Send prompt to model)" do
      stdin = IO::Memory.new("2\n")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      action, payload = Salamander::Fuzzy.choose_action(
        "/last_context",
        "/print_context",
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      action.should eq(Salamander::Fuzzy::Action::SendPrompt)
      payload.should eq("/last_context")
    end

    it "handles option 3 / cancel" do
      stdin = IO::Memory.new("3\n")
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      action, payload = Salamander::Fuzzy.choose_action(
        "/last_context",
        "/print_context",
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      action.should eq(Salamander::Fuzzy::Action::Cancel)
      stdout.to_s.should contain("Cancelled.")
    end

    it "handles unrecognized command with no close match" do
      stdin = IO::Memory.new("1\n") # Send to model
      stdout = IO::Memory.new
      stderr = IO::Memory.new

      action, payload = Salamander::Fuzzy.choose_action(
        "/unmatched_xyz",
        nil,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr
      )

      action.should eq(Salamander::Fuzzy::Action::SendPrompt)
      payload.should eq("/unmatched_xyz")
      stdout.to_s.should contain("1. Send '/unmatched_xyz' as prompt to model")
    end
  end
end
