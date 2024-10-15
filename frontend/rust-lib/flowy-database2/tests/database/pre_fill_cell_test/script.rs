use crate::database::database_editor::DatabaseEditorTest;
use collab_database::fields::select_type_option::{SelectOptionIds, SELECTION_IDS_SEPARATOR};
use flowy_database2::entities::{CreateRowPayloadPB, FilterDataPB, InsertFilterPB};
use flowy_database2::services::cell::stringify_cell;
use std::ops::{Deref, DerefMut};
use std::time::Duration;

pub struct DatabasePreFillRowCellTest {
  inner: DatabaseEditorTest,
}

impl DatabasePreFillRowCellTest {
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

  pub async fn create_row_with_payload(&mut self, payload: CreateRowPayloadPB) {
    let row_detail = self.editor.create_row(payload).await.unwrap().unwrap();
    self
      .row_by_row_id
      .insert(row_detail.row.id.to_string(), row_detail.into());
    self.rows = self.get_rows().await;
  }

  pub async fn insert_filter(&mut self, filter: FilterDataPB) {
    self
      .editor
      .modify_view_filters(
        &self.view_id,
        InsertFilterPB {
          parent_filter_id: None,
          data: filter,
        }
        .try_into()
        .unwrap(),
      )
      .await
      .unwrap();
  }

  pub async fn assert_row_count(&self, expected_row_count: usize) {
    let rows = self.editor.get_all_rows(&self.view_id).await.unwrap();
    assert_eq!(expected_row_count, rows.len());
  }

  pub async fn assert_cell_existence(&self, field_id: String, row_index: usize, exists: bool) {
    let rows = self.editor.get_all_rows(&self.view_id).await.unwrap();
    let row = rows.get(row_index).unwrap();
    let cell = row.cells.get(&field_id).cloned();
    assert_eq!(exists, cell.is_some());
  }

  pub async fn assert_cell_content(
    &self,
    field_id: String,
    row_index: usize,
    expected_content: String,
  ) {
    let field = self.editor.get_field(&field_id).await.unwrap();
    let rows = self.editor.get_all_rows(&self.view_id).await.unwrap();
    let row = rows.get(row_index).unwrap();
    let cell = row.cells.get(&field_id).cloned().unwrap_or_default();
    let content = stringify_cell(&cell, &field);
    assert_eq!(content, expected_content);
  }

  pub async fn assert_select_option_cell_strict(
    &self,
    field_id: String,
    row_index: usize,
    expected_content: String,
  ) {
    let rows = self.editor.get_all_rows(&self.view_id).await.unwrap();
    let row = rows.get(row_index).unwrap();
    let cell = row.cells.get(&field_id).cloned().unwrap_or_default();
    let content = SelectOptionIds::from(&cell).join(SELECTION_IDS_SEPARATOR);
    assert_eq!(content, expected_content);
  }

  pub async fn wait(&self, milliseconds: u64) {
    tokio::time::sleep(Duration::from_millis(milliseconds)).await;
  }
}

impl Deref for DatabasePreFillRowCellTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl DerefMut for DatabasePreFillRowCellTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
