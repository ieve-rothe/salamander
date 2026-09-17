require "../spec_helper"

describe Salamander::UI::Editor do
  describe ".resolve_editor" do
    it "prefers explicit override when provided" do
      Salamander::UI::Editor.resolve_editor("my-custom-editor").should eq("my-custom-editor")
    end

    it "falls back to ENV[\"EDITOR\"] when override is nil or empty" do
      orig_editor = ENV["EDITOR"]?
      orig_visual = ENV["VISUAL"]?
      begin
        ENV["EDITOR"] = "custom-ed"
        ENV["VISUAL"] = "custom-vis"
        Salamander::UI::Editor.resolve_editor(nil).should eq("custom-ed")
        Salamander::UI::Editor.resolve_editor("  ").should eq("custom-ed")
      ensure
        if orig_editor
          ENV["EDITOR"] = orig_editor
        else
          ENV.delete("EDITOR")
        end
        if orig_visual
          ENV["VISUAL"] = orig_visual
        else
          ENV.delete("VISUAL")
        end
      end
    end

    it "falls back to ENV[\"VISUAL\"] when EDITOR is unset" do
      orig_editor = ENV["EDITOR"]?
      orig_visual = ENV["VISUAL"]?
      begin
        ENV.delete("EDITOR")
        ENV["VISUAL"] = "custom-vis"
        Salamander::UI::Editor.resolve_editor(nil).should eq("custom-vis")
      ensure
        if orig_editor
          ENV["EDITOR"] = orig_editor
        else
          ENV.delete("EDITOR")
        end
        if orig_visual
          ENV["VISUAL"] = orig_visual
        else
          ENV.delete("VISUAL")
        end
      end
    end
  end

  describe ".edit" do
    it "executes interactive edit on tempfile and returns updated text on exit 0" do
      mock_editor = "sh -c 'echo \"Updated Content\" >> \"$1\"' --"
      res = Salamander::UI::Editor.edit(
        initial_text: "Original Text",
        editor_override: mock_editor
      )
      res.should eq("Original Text\nUpdated Content")
    end

    it "returns nil and writes notice on non-zero exit" do
      err_io = IO::Memory.new
      mock_failing_editor = "sh -c 'exit 2' --"
      res = Salamander::UI::Editor.edit(
        initial_text: "Original Text",
        editor_override: mock_failing_editor,
        io_err: err_io
      )
      res.should be_nil
      err_io.to_s.should contain("Notice: Editor exited with non-zero status (2)")
    end

    it "returns nil when editor terminates abnormally via signal" do
      err_io = IO::Memory.new
      mock_killed = "sh -c 'kill -9 $$' --"
      res = Salamander::UI::Editor.edit(
        initial_text: "Original Text",
        editor_override: mock_killed,
        io_err: err_io
      )
      res.should be_nil
      err_io.to_s.should contain("Notice: Editor exited with non-zero status")
      err_io.to_s.should contain("signal KILL")
    end

    it "returns nil and warns when edited content is empty" do
      err_io = IO::Memory.new
      mock_empty = "sh -c '> \"$1\"' --"
      res = Salamander::UI::Editor.edit(
        initial_text: "Original Text",
        editor_override: mock_empty,
        io_err: err_io
      )
      res.should be_nil
      err_io.to_s.should contain("Warning: Edited content was empty. Retaining previous content.")
    end

    it "returns nil and warns when tempfile is deleted by editor" do
      err_io = IO::Memory.new
      mock_delete = "sh -c 'rm -f \"$1\"' --"
      res = Salamander::UI::Editor.edit(
        initial_text: "Original Text",
        editor_override: mock_delete,
        io_err: err_io
      )
      res.should be_nil
      err_io.to_s.should contain("Warning: Edited temporary file was removed. Retaining previous content.")
    end

    it "cleans up tempfile on completion" do
      canary_file = File.tempfile("editor_canary").path
      File.delete(canary_file) if File.exists?(canary_file)

      record_editor = "sh -c 'echo \"$1\" > #{canary_file}; echo \"Success\" > \"$1\"' --"
      Salamander::UI::Editor.edit("Test", editor_override: record_editor)

      temp_path = File.read(canary_file).strip
      File.exists?(temp_path).should be_false
      File.delete(canary_file) if File.exists?(canary_file)
    end
  end
end
