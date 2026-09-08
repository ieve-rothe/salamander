require "../spec_helper"

describe Salamander::UI::MarkdownFormatter do
  it "formats bold text" do
    result = Salamander::UI::MarkdownFormatter.format("This is **bold** text")
    result.should eq("This is \e[1;97mbold\e[0m text")
  end

  it "formats italic text" do
    result = Salamander::UI::MarkdownFormatter.format("This is *italic* text")
    result.should eq("This is \e[3mitalic\e[0m text")
  end

  it "formats multi-line code blocks and protects inner characters" do
    result = Salamander::UI::MarkdownFormatter.format("```ruby\nputs *x* # header\n```")
    result.should eq("\e[48;5;236mruby\nputs *x* # header\n\e[0m")
  end

  it "formats inline code and protects inner characters" do
    result = Salamander::UI::MarkdownFormatter.format("Here is `a * b # test`")
    result.should eq("Here is \e[48;5;236ma * b # test\e[0m")
  end

  it "formats headers" do
    result = Salamander::UI::MarkdownFormatter.format("# Header 1")
    result.should eq("\e[1;36m# Header 1\e[0m")
  end

  it "formats links" do
    result = Salamander::UI::MarkdownFormatter.format("A [link](http://example.com)")
    result.should eq("A \e[34mlink\e[0m (\e[4;34mhttp://example.com\e[0m)")
  end

  it "formats blockquotes" do
    result = Salamander::UI::MarkdownFormatter.format("> Quote here")
    result.should eq("\e[3;90m> Quote here\e[0m")
  end

  it "handles multiple formats in a single string" do
    text = "Here is **bold** and `code`"
    result = Salamander::UI::MarkdownFormatter.format(text)
    result.should eq("Here is \e[1;97mbold\e[0m and \e[48;5;236mcode\e[0m")
  end

  it "restores parent ANSI styling in blockquotes without bleeding \e[0m reset" do
    text = "> This is **bold** in a blockquote"
    result = Salamander::UI::MarkdownFormatter.format(text)
    result.should eq("\e[3;90m> This is \e[1;97mbold\e[3;90m in a blockquote\e[0m")
  end

  it "restores parent ANSI styling in headers without bleeding \e[0m reset" do
    text = "# Header with **bold**"
    result = Salamander::UI::MarkdownFormatter.format(text)
    result.should eq("\e[1;36m# Header with \e[1;97mbold\e[1;36m\e[0m")
  end

  describe Salamander::UI::MarkdownFormatter::IncrementalLexer do
    it "processes chunk tokens in-flight" do
      lexer = Salamander::UI::MarkdownFormatter::IncrementalLexer.new
      result = lexer.process_chunk("Hello **world**")
      result.should eq("Hello \e[1;97mworld\e[0m")
    end
  end
end
