use tantivy::schema::Schema;

pub const FOLDER_ID_FIELD_NAME: &str = "id";
pub const FOLDER_TITLE_FIELD_NAME: &str = "title";

#[derive(Clone)]
pub struct FolderSchema {
  pub schema: Schema,
}

impl FolderSchema {
  pub fn new() -> Self {
    let mut schema_builder = Schema::builder();
    schema_builder.add_text_field(FOLDER_ID_FIELD_NAME, tantivy::schema::TEXT);
    schema_builder.add_text_field(
      FOLDER_TITLE_FIELD_NAME,
      tantivy::schema::TEXT | tantivy::schema::STORED,
    );

    let schema = schema_builder.build();

    Self { schema }
  }
}
