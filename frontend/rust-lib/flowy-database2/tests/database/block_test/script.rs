use crate::database::database_editor::DatabaseEditorTest;
use collab_database::rows::RowId;
use flowy_database2::entities::CreateRowPayloadPB;

pub struct DatabaseRowTest {
  inner: DatabaseEditorTest,
}

impl DatabaseRowTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self { inner: editor_test }
  }

  pub async fn create_empty_row(&mut self) {
    let params = CreateRowPayloadPB {
      view_id: self.view_id.clone(),
      ..Default::default()
    };
    let row_detail = self.editor.create_row(params).await.unwrap().unwrap();
    self
      .row_by_row_id
      .insert(row_detail.row.id.to_string(), row_detail.into());
    self.rows = self.get_rows().await;
  }

  pub async fn update_text_cell(&mut self, row_id: RowId, content: &str) {
    self.inner.update_text_cell(row_id, content).await.unwrap();
  }

  pub async fn assert_row_count(&self, expected_row_count: usize) {
    assert_eq!(expected_row_count, self.rows.len());
  }
}

impl std::ops::Deref for DatabaseRowTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseRowTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
