require "./spec_helper"

describe Salamander::ChatSession do
  it "starts in evaluating state" do
    session = Salamander::ChatSession.new
    session.evaluating?.should be_true
    session.thinking?.should be_false
    session.responding?.should be_false
  end

  describe "with standard Mantle v1.0.0 <think> tags" do
    it "transitions Evaluating -> Thinking -> Responding and isolates thinking log" do
      state_history = [] of Salamander::ChatSession::State
      session = Salamander::ChatSession.new(on_state_change: ->(state : Salamander::ChatSession::State) {
        state_history << state
      })

      # 1. Chunk with opening <think>
      c1 = session.process_chunk("<think>Let's consider the user's question.")
      c1.state.should eq(Salamander::ChatSession::State::Thinking)
      c1.state_changed.should be_true
      c1.content.should eq("")
      session.thinking?.should be_true

      # 2. Intermediate thinking chunk
      c2 = session.process_chunk("\nWe should answer concisely.")
      c2.state.should eq(Salamander::ChatSession::State::Thinking)
      c2.state_changed.should be_false
      c2.content.should eq("")

      # 3. Chunk with closing </think> and initial response content
      c3 = session.process_chunk("</think>Hello! How can I help?")
      c3.state.should eq(Salamander::ChatSession::State::Responding)
      c3.state_changed.should be_true
      c3.content.should eq("Hello! How can I help?")
      session.responding?.should be_true

      # 4. Continuation response chunk
      c4 = session.process_chunk(" Let me know.")
      c4.state.should eq(Salamander::ChatSession::State::Responding)
      c4.state_changed.should be_false
      c4.content.should eq(" Let me know.")

      session.thinking_log.should eq("Let's consider the user's question.\nWe should answer concisely.")
      state_history.should eq([
        Salamander::ChatSession::State::Thinking,
        Salamander::ChatSession::State::Responding,
      ])
    end
  end

  describe "with legacy <|think|> tags" do
    it "transitions Evaluating -> Thinking -> Responding" do
      session = Salamander::ChatSession.new

      c1 = session.process_chunk("<|think|>Step 1...")
      c1.state.should eq(Salamander::ChatSession::State::Thinking)
      c1.content.should eq("")

      c2 = session.process_chunk("</|think|>Answer here.")
      c2.state.should eq(Salamander::ChatSession::State::Responding)
      c2.content.should eq("Answer here.")

      session.thinking_log.should eq("Step 1...")
    end
  end

  describe "without thinking tags" do
    it "transitions Evaluating -> Responding on first chunk" do
      session = Salamander::ChatSession.new

      c1 = session.process_chunk("Direct response text.")
      c1.state.should eq(Salamander::ChatSession::State::Responding)
      c1.state_changed.should be_true
      c1.content.should eq("Direct response text.")
      session.responding?.should be_true
      session.thinking_log.should eq("")
    end
  end
end
