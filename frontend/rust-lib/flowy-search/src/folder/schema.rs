use tantivy::schema::Schema;

pub const FOLDER_ID_FIELD_NAME: &str = "id";
pub const FOLDER_TITLE_FIELD_NAME: &str = "title";
pub const FOLDER_ICON_FIELD_NAME: &str = "icon";
pub const FOLDER_ICON_TY_FIELD_NAME: &str = "icon_ty";

#[derive(Clone)]
pub struct FolderSchema {
  pub schema: Schema,
}

/// Do not change the schema after the index has been created.
/// Changing field_options or fields, will result in the schema being different
/// from previously created index, causing tantivy to panic and search to stop functioning.
///
/// If you need to change the schema, create a migration that removes the old index,
/// and creates a new one with the new schema.
///
impl FolderSchema {
  pub fn new() -> Self {
    let mut schema_builder = Schema::builder();
    schema_builder.add_text_field(
      FOLDER_ID_FIELD_NAME,
      tantivy::schema::STRING | tantivy::schema::STORED,
    );
    schema_builder.add_text_field(
      FOLDER_TITLE_FIELD_NAME,
      tantivy::schema::TEXT | tantivy::schema::STORED,
    );
    schema_builder.add_text_field(
      FOLDER_ICON_FIELD_NAME,
      tantivy::schema::TEXT | tantivy::schema::STORED,
    );
    schema_builder.add_i64_field(FOLDER_ICON_TY_FIELD_NAME, tantivy::schema::STORED);

    let schema = schema_builder.build();

    Self { schema }
  }
}

impl Default for FolderSchema {
  fn default() -> Self {
    Self::new()
  }
}
