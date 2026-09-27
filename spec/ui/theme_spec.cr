require "../spec_helper"

describe Salamander::UI::Theme do
  after_each do
    Salamander::UI::Theme.set_theme("cupertino")
  end

  it "lists all available theme names" do
    names = Salamander::UI::Theme.all_names
    names.should contain("cupertino")
    names.should contain("apple")
    names.should contain("cyberpunk")
    names.should contain("outrun")
    names.should contain("phosphor")
    names.should contain("classic")
  end

  it "defaults to cupertino theme" do
    Salamander::UI::Theme.current.name.should eq("cupertino")
    Salamander::UI::Theme.prompt_glyph.should contain("›")
  end

  it "switches to apple alias" do
    Salamander::UI::Theme.set_theme("apple")
    Salamander::UI::Theme.current.name.should eq("cupertino")
  end

  it "switches to cyberpunk theme" do
    Salamander::UI::Theme.set_theme("cyberpunk")
    Salamander::UI::Theme.current.name.should eq("cyberpunk")
    Salamander::UI::Theme.prompt_glyph.should contain("❯❯")
  end

  it "switches to outrun theme" do
    Salamander::UI::Theme.set_theme("outrun")
    Salamander::UI::Theme.current.name.should eq("outrun")
    Salamander::UI::Theme.prompt_glyph.should contain("❯")
    Salamander::UI::Theme.pill("y", "ALLOW").should contain("[y]")
  end

  it "switches to phosphor theme" do
    Salamander::UI::Theme.set_theme("phosphor")
    Salamander::UI::Theme.current.name.should eq("phosphor")
    Salamander::UI::Theme.prompt_glyph.should contain("▶")
  end

  it "switches to classic theme" do
    Salamander::UI::Theme.set_theme("classic")
    Salamander::UI::Theme.current.name.should eq("classic")
    Salamander::UI::Theme.prompt_glyph.should eq("> ")
  end

  it "raises ArgumentError on unknown theme name" do
    expect_raises(ArgumentError, /Unknown theme/) do
      Salamander::UI::Theme.set_theme("neon_cat")
    end
  end

  it "renders panels with different box styles" do
    panel_sharp = Salamander::UI::Panel.new(40, Salamander::UI::BoxStyle::Sharp)
    hdr_sharp = panel_sharp.render_header("Sharp Box")
    Salamander::UI::Panel.strip_ansi(hdr_sharp).should start_with("┌─")

    panel_armored = Salamander::UI::Panel.new(40, Salamander::UI::BoxStyle::Armored)
    hdr_armored = panel_armored.render_header("Armored Box")
    Salamander::UI::Panel.strip_ansi(hdr_armored).should start_with("╔═")
    row_armored = panel_armored.render_row("Secure row")
    Salamander::UI::Panel.strip_ansi(row_armored).should start_with("║")
    ftr_armored = panel_armored.render_footer
    Salamander::UI::Panel.strip_ansi(ftr_armored).should start_with("╚═")
  end
end
