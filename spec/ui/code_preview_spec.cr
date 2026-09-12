require "../spec_helper"

describe Salamander::UI::CodePreview do
  it "renders code slice with line numbers" do
    panel = Salamander::UI::Panel.new(60)
    lines = ["def foo", "  42", "end"]
    rendered = Salamander::UI::CodePreview.render(lines, start_offset: 10, max_preview_lines: 5, panel: panel)

    rendered.size.should eq(3)
    Salamander::UI::Panel.strip_ansi(rendered[0]).should contain("10 │ def foo")
    Salamander::UI::Panel.strip_ansi(rendered[1]).should contain("11 │   42")
    Salamander::UI::Panel.strip_ansi(rendered[2]).should contain("12 │ end")
  end

  it "renders truncation notice when lines exceed max_preview_lines" do
    panel = Salamander::UI::Panel.new(60)
    lines = (1..20).map { |i| "line_#{i}" }
    rendered = Salamander::UI::CodePreview.render(lines, start_offset: 1, max_preview_lines: 3, panel: panel)

    rendered.size.should eq(4)
    Salamander::UI::Panel.strip_ansi(rendered[3]).should contain("17 more lines hidden")
  end
end
