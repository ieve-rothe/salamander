# src/salamander/ui/editor.cr

module Salamander
  class UI
    module Editor
      extend self

      def resolve_editor(override : String? = nil) : String?
        return override if override && !override.strip.empty?

        if env_editor = ENV["EDITOR"]?
          return env_editor unless env_editor.strip.empty?
        end

        if env_visual = ENV["VISUAL"]?
          return env_visual unless env_visual.strip.empty?
        end

        ["nano", "vim", "vi"].each do |candidate|
          if path = Process.find_executable(candidate)
            return path
          end
        end

        nil
      end

      def edit(
        initial_text : String,
        editor_override : String? = nil,
        io_in : IO = STDIN,
        io_out : IO = STDOUT,
        io_err : IO = STDERR,
        tempfile_prefix : String = "salamander_edit_",
        tempfile_suffix : String = ".md",
        subject : String = "content"
      ) : String?
        editor = resolve_editor(editor_override)
        unless editor
          io_err.puts "Error: No editor found in $EDITOR, $VISUAL, or PATH (nano, vim, vi)."
          return nil
        end

        tempfile = File.tempfile(tempfile_prefix, tempfile_suffix)
        temp_path = tempfile.path

        begin
          tempfile.puts(initial_text)
          tempfile.flush
          tempfile.close

          cmd = "#{editor} #{Process.quote(temp_path)}"
          status = Process.run(
            command: "/bin/sh",
            args: ["-c", cmd],
            input: io_in,
            output: io_out,
            error: io_err
          )

          if status.success?
            unless File.exists?(temp_path)
              io_err.puts "Warning: Edited temporary file was removed. Retaining previous #{subject}."
              return nil
            end

            edited_content = File.read(temp_path).strip
            if edited_content.empty?
              io_err.puts "Warning: Edited #{subject} was empty. Retaining previous #{subject}."
              return nil
            end

            edited_content
          else
            status_desc = status.normal_exit? ? status.exit_code.to_s : "signal #{status.exit_signal? || "UNKNOWN"}"
            io_err.puts "Notice: Editor exited with non-zero status (#{status_desc}). In-memory #{subject} unchanged."
            nil
          end
        rescue ex : Exception
          io_err.puts "Warning: Error during editor execution: #{ex.message}. In-memory #{subject} unchanged."
          nil
        ensure
          File.delete(temp_path) if File.exists?(temp_path)
        end
      end
    end
  end
end
