# src/salamander/chat_session.cr

module Salamander
  # ==============================================================================
  # CHAT SESSION - STREAMING STATE MACHINE
  # ==============================================================================
  # This class encapsulates the streaming response state machine, tracking:
  #   - Current state (:evaluating, :thinking, :responding)
  #   - Thinking block content (hidden from terminal)
  #   - State transitions based on LLM tags
  # ==============================================================================
  class ChatSession
    enum State
      Evaluating # Model is loading/working
      Thinking   # Inside <|think|> block
      Responding # Streaming visible content
    end

    @state : State
    @hidden_thinking_log : String::Builder
    @on_state_change : Proc(State, Nil)?

    getter state

    def initialize(@on_state_change : Proc(State, Nil)? = nil)
      @state = State::Evaluating
      @hidden_thinking_log = String::Builder.new
    end

    # Process a chunk from the LLM stream
    # Returns ProcessedChunk with clean content and metadata
    def process_chunk(chunk : String) : ProcessedChunk
      # Track whether state changed this chunk
      state_changed = false
      old_state = @state

      # -------------------- State Transitions --------------------

      # Transition: Evaluating → Thinking
      if chunk.includes?("<|think|>")
        @state = State::Thinking
        state_changed = true
      end

      # Transition: Thinking → Responding
      if chunk.includes?("</|think|>") && @state != State::Responding
        @state = State::Responding
        state_changed = true
      end

      # Transition: Evaluating → Responding (no thinking block)
      if @state == State::Evaluating && !chunk.includes?("<|think|>")
        @state = State::Responding
        state_changed = true
      end

      # Notify listener of state change
      if state_changed && (callback = @on_state_change)
        callback.call(@state)
      end

      # -------------------- Chunk Processing --------------------

      clean_content = ""

      case @state
      when .thinking?
        # Accumulate thinking content in memory (don't show in terminal)
        @hidden_thinking_log << chunk
      when .responding?
        # Strip closing tag if present (prevent </|think|> from appearing in output)
        clean_content = chunk.gsub("</|think|>", "")
      end

      ProcessedChunk.new(
        content: clean_content,
        state: @state,
        state_changed: state_changed,
        old_state: old_state
      )
    end

    # Get the accumulated thinking content
    def thinking_log : String
      @hidden_thinking_log.to_s
    end

    # Check if currently in a specific state
    def evaluating? : Bool
      @state.evaluating?
    end

    def thinking? : Bool
      @state.thinking?
    end

    def responding? : Bool
      @state.responding?
    end

    # Result of processing a chunk
    struct ProcessedChunk
      property content : String     # Clean content to display (empty if thinking)
      property state : State        # Current state after processing
      property state_changed : Bool # Whether state changed during this chunk
      property old_state : State    # Previous state (useful for transitions)

      def initialize(@content, @state, @state_changed, @old_state)
      end
    end
  end
end
