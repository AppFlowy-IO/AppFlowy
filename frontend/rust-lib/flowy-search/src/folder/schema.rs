use tantivy::schema::Schema;

pub const FOLDER_ID_FIELD_NAME: &str = "id";
pub const FOLDER_TITLE_FIELD_NAME: &str = "title";

#[derive(Clone)]
pub struct FolderSchema {
  pub schema: Schema,
}

/// Do not change the schema after the index has been created.
/// Changing field_options or fields, will result in the schema being different
/// from previously created index, causing tantivy to panic.
///
impl FolderSchema {
  pub fn new() -> Self {
    let mut schema_builder = Schema::builder();
    schema_builder.add_text_field(
      FOLDER_ID_FIELD_NAME,
      tantivy::schema::TEXT | tantivy::schema::STORED,
    );
    schema_builder.add_text_field(
      FOLDER_TITLE_FIELD_NAME,
      tantivy::schema::TEXT | tantivy::schema::STORED,
    );

    let schema = schema_builder.build();

    Self { schema }
  }
}
