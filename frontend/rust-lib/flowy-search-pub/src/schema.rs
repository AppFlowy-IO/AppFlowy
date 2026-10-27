use crate::tokenizer::CJK_AWARE_TOKENIZER;
use tantivy::schema::{
  IndexRecordOption, STORED, STRING, Schema, TEXT, TextFieldIndexing, TextOptions,
};

pub struct LocalSearchTantivySchema(pub Schema);

impl Default for LocalSearchTantivySchema {
  fn default() -> Self {
    Self::new()
  }
}

impl LocalSearchTantivySchema {
  pub const WORKSPACE_ID: &'static str = "workspace_id";
  pub const OBJECT_ID: &'static str = "object_id";
  pub const CONTENT: &'static str = "content";
  pub const NAME: &'static str = "name";
  pub const ICON: &'static str = "icon";
  pub const ICON_TYPE: &'static str = "icon_ty";

  pub fn new() -> Self {
    // Searchable text is split with the CJK aware tokenizer so that Japanese, Chinese
    // and Korean text can be matched by any substring, not only by its first word.
    let searchable_text = TextOptions::default()
      .set_indexing_options(
        TextFieldIndexing::default()
          .set_tokenizer(CJK_AWARE_TOKENIZER)
          .set_index_option(IndexRecordOption::WithFreqsAndPositions),
      )
      .set_stored();

    let mut builder = Schema::builder();
    builder.add_text_field(Self::WORKSPACE_ID, STRING | STORED);
    builder.add_text_field(Self::OBJECT_ID, STRING | STORED);
    builder.add_text_field(Self::CONTENT, searchable_text.clone());
    builder.add_text_field(Self::NAME, searchable_text);
    builder.add_text_field(Self::ICON, TEXT | STORED);
    builder.add_text_field(Self::ICON_TYPE, STRING | STORED);
    LocalSearchTantivySchema(builder.build())
  }
}
