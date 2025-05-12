use lopdf::Document;

pub struct PdfRead {
  path: String,
}

impl PdfRead {
  pub fn new<P: Into<String>>(path: P) -> Self {
    PdfRead { path: path.into() }
  }

  /// Loads the PDF and extracts text from all pages, concatenated with double newlines.
  pub fn read_all(&self) -> lopdf::Result<String> {
    let doc = Document::load(&self.path)?;
    // Get a map of page numbers to object IDs
    let pages = doc.get_pages();
    let mut texts = Vec::with_capacity(pages.len());

    // Iterate pages in ascending order
    let mut page_numbers: Vec<u32> = pages.keys().cloned().collect();
    page_numbers.sort_unstable();
    for page_num in page_numbers {
      // Extract text for this page
      let page_text = doc.extract_text(&[page_num])?;
      texts.push(page_text);
    }

    // Join all pages with blank line separators
    Ok(texts.join("\n\n"))
  }
}
