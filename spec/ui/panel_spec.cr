require "../spec_helper"

describe Salamander::UI::Panel do
  it "clamps width correctly" do
    Salamander::UI::Panel.clamp_width(255, max_width: 105).should eq(105)
    Salamander::UI::Panel.clamp_width(80, max_width: 105, padding: 4).should eq(76)
    Salamander::UI::Panel.clamp_width(15, max_width: 105).should eq(20) # min 20
  end

  it "computes visual_width correctly with ANSI and emojis" do
    Salamander::UI::Panel.visual_width("hello").should eq(5)
    Salamander::UI::Panel.visual_width("\e[32mhello\e[0m").should eq(5)
    Salamander::UI::Panel.visual_width("📚 Opened Files").should eq(15) # 📚 is 2 cols + 13 chars
    Salamander::UI::Panel.visual_width("🔍 Inspection").should eq(13)   # 🔍 is 2 cols + 11 chars
  end

  it "guarantees exact visual width across header, row, divider, and footer" do
    [30, 45, 65, 80, 105].each do |w|
      panel = Salamander::UI::Panel.new(w)

      hdr_no_badge = panel.render_header("Title")
      Salamander::UI::Panel.visual_width(hdr_no_badge).should eq(w)

      hdr_badge = panel.render_header("Title", "BADGE")
      Salamander::UI::Panel.visual_width(hdr_badge).should eq(w)

      row = panel.render_row("Test content")
      Salamander::UI::Panel.visual_width(row).should eq(w)

      div = panel.render_divider
      Salamander::UI::Panel.visual_width(div).should eq(w)

      ftr = panel.render_footer
      Salamander::UI::Panel.visual_width(ftr).should eq(w)
    end
  end

  it "guarantees header never exceeds width even with long title, badge, and emojis" do
    panel = Salamander::UI::Panel.new(65)
    long_title = "📚 Opened Files (5 files · 8.4 KB · ~4.8k tok)"
    long_badge = "ALL IN ONE BOX"

    hdr = panel.render_header(long_title, long_badge)
    Salamander::UI::Panel.visual_width(hdr).should eq(65)
    Salamander::UI::Panel.strip_ansi(hdr).should start_with("╭─")
    Salamander::UI::Panel.strip_ansi(hdr).should end_with("╮")
  end

  it "guarantees row never exceeds width even when content is very long" do
    panel = Salamander::UI::Panel.new(50)
    long_str = "A" * 200
    row = panel.render_row(long_str, truncate: true)
    Salamander::UI::Panel.visual_width(row).should eq(50)
    Salamander::UI::Panel.strip_ansi(row).should start_with("│")
    Salamander::UI::Panel.strip_ansi(row).should end_with("│")
  end

  it "renders wrapped rows where every row has exact visual width" do
    panel = Salamander::UI::Panel.new(50)
    long_prompt = "Please see if you need to make any updates to the daily ledger or decision log, or the current bead.md, based on our current progress."
    rows = panel.render_wrapped_row(long_prompt)
    rows.size.should be > 1
    rows.each do |r|
      Salamander::UI::Panel.visual_width(r).should eq(50)
      Salamander::UI::Panel.strip_ansi(r).should start_with("│")
      Salamander::UI::Panel.strip_ansi(r).should end_with("│")
    end
  end
end
