require "../spec_helper"

describe Salamander::UI::Panel do
  it "clamps width correctly" do
    Salamander::UI::Panel.clamp_width(255, max_width: 105).should eq(105)
    Salamander::UI::Panel.clamp_width(80, max_width: 105, padding: 4).should eq(76)
  end

  it "renders header with title and border" do
    panel = Salamander::UI::Panel.new(60)
    hdr = panel.render_header("My Title")
    Salamander::UI::Panel.strip_ansi(hdr).should contain("My Title")
    Salamander::UI::Panel.strip_ansi(hdr).should start_with("╭─")
    Salamander::UI::Panel.strip_ansi(hdr).should end_with("╮")
  end

  it "renders header with badge" do
    panel = Salamander::UI::Panel.new(60)
    hdr = panel.render_header("Title", "BADGE")
    Salamander::UI::Panel.strip_ansi(hdr).should contain("Title")
    Salamander::UI::Panel.strip_ansi(hdr).should contain("BADGE")
  end

  it "renders rows, dividers, and footers" do
    panel = Salamander::UI::Panel.new(50)
    row = panel.render_row("Test content")
    Salamander::UI::Panel.strip_ansi(row).should contain("Test content")
    Salamander::UI::Panel.strip_ansi(row).should start_with("│")
    Salamander::UI::Panel.strip_ansi(row).should end_with("│")

    div = panel.render_divider
    Salamander::UI::Panel.strip_ansi(div).should start_with("├")
    Salamander::UI::Panel.strip_ansi(div).should end_with("┤")

    ftr = panel.render_footer
    Salamander::UI::Panel.strip_ansi(ftr).should start_with("╰")
    Salamander::UI::Panel.strip_ansi(ftr).should end_with("╯")
  end
end
