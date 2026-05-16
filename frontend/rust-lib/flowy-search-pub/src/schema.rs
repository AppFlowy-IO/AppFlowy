use tantivy::schema::{STORED, STRING, Schema, TEXT};

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
    let mut builder = Schema::builder();
    builder.add_text_field(Self::WORKSPACE_ID, STRING | STORED);
    builder.add_text_field(Self::OBJECT_ID, STRING | STORED);
    builder.add_text_field(Self::CONTENT, TEXT | STORED);
    builder.add_text_field(Self::NAME, TEXT | STORED);
    builder.add_text_field(Self::ICON, TEXT | STORED);
    builder.add_text_field(Self::ICON_TYPE, STRING | STORED);
    LocalSearchTantivySchema(builder.build())
  }
}
