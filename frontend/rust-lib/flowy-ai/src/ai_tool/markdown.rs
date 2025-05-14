use pulldown_cmark::{Options, Parser, html};
use std::fs;

pub struct MdRead {
  path: String,
}

impl MdRead {
  /// Creates a new MdRead for the given file path.
  pub fn new<P: Into<String>>(path: P) -> Self {
    MdRead { path: path.into() }
  }

  pub fn read_markdown(&self) -> std::io::Result<String> {
    fs::read_to_string(&self.path)
  }

  /// Renders the markdown to HTML, with CommonMark extensions enabled.
  pub fn render_html(&self) -> Result<String, Box<dyn std::error::Error>> {
    let markdown_input = self.read_markdown()?;
    // Set up parser options (tables, footnotes, strikethrough)
    let mut options = Options::empty();
    options.insert(Options::ENABLE_TABLES);
    options.insert(Options::ENABLE_FOOTNOTES);
    options.insert(Options::ENABLE_STRIKETHROUGH);
    // Create parser and render HTML
    let parser = Parser::new_ext(&markdown_input, options);
    let mut html_output = String::with_capacity(markdown_input.len() * 3 / 2);
    html::push_html(&mut html_output, parser);
    Ok(html_output)
  }
}
