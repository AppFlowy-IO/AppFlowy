use crate::database::database_editor::DatabaseEditorTest;
use collab_database::fields::{Field, TypeOptionData};
use flowy_database2::entities::{CreateFieldParams, FieldChangesetPB, FieldType};
use flowy_database2::services::cell::stringify_cell;

pub struct DatabaseFieldTest {
  inner: DatabaseEditorTest,
}

impl DatabaseFieldTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self { inner: editor_test }
  }

  pub fn view_id(&self) -> String {
    self.view_id.clone()
  }

  pub fn field_count(&self) -> usize {
    self.field_count
  }

  pub async fn create_field(&mut self, params: CreateFieldParams) {
    self.field_count += 1;
    let _ = self.editor.create_field_with_type_option(params).await;
    let fields = self.editor.get_fields(&self.view_id, None).await;
    assert_eq!(self.field_count, fields.len());
  }

  pub async fn update_field(&mut self, changeset: FieldChangesetPB) {
    self.editor.update_field(changeset).await.unwrap();
  }

  pub async fn delete_field(&mut self, field: Field) {
    if self.editor.get_field(&field.id).await.is_some() {
      self.field_count -= 1;
    }

    self.editor.delete_field(&field.id).await.unwrap();
    let fields = self.editor.get_fields(&self.view_id, None).await;
    assert_eq!(self.field_count, fields.len());
  }

  pub async fn switch_to_field(
    &mut self,
    view_id: String,
    field_id: String,
    new_field_type: FieldType,
  ) {
    self
      .editor
      .switch_to_field_type(&view_id, &field_id, new_field_type, None)
      .await
      .unwrap();
  }

  pub async fn update_type_option(&mut self, field_id: String, type_option: TypeOptionData) {
    let old_field = self.editor.get_field(&field_id).await.unwrap();
    self
      .editor
      .update_field_type_option(&field_id, type_option, old_field)
      .await
      .unwrap();
  }

  pub async fn assert_field_count(&self, count: usize) {
    assert_eq!(self.get_fields().await.len(), count);
  }

  pub async fn assert_field_type_option_equal(
    &self,
    field_index: usize,
    expected_type_option_data: TypeOptionData,
  ) {
    let fields = self.get_fields().await;
    let field = &fields[field_index];
    let type_option_data = field.get_any_type_option(field.field_type).unwrap();
    assert_eq!(type_option_data, expected_type_option_data);
  }

  pub async fn assert_cell_content(
    &self,
    field_id: String,
    row_index: usize,
    expected_content: String,
  ) {
    let field = self.editor.get_field(&field_id).await.unwrap();

    let rows = self.editor.get_all_rows(&self.view_id()).await.unwrap();
    let row = rows.get(row_index).unwrap();

    let cell = row.cells.get(&field_id).unwrap().clone();
    let content = stringify_cell(&cell, &field);
    assert_eq!(content, expected_content);
  }
}

impl std::ops::Deref for DatabaseFieldTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseFieldTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
