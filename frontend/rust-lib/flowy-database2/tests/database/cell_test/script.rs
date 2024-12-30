use crate::database::database_editor::DatabaseEditorTest;
use collab_database::rows::RowId;
use lib_infra::box_any::BoxAny;

pub struct DatabaseCellTest {
  inner: DatabaseEditorTest,
}

impl DatabaseCellTest {
  pub async fn new() -> Self {
    let inner = DatabaseEditorTest::new_grid().await;
    Self { inner }
  }

  pub async fn update_cell(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: &RowId,
    changeset: BoxAny,
  ) {
    self
      .editor
      .update_cell_with_changeset(view_id, row_id, field_id, changeset)
      .await
      .unwrap();
  }
}

impl std::ops::Deref for DatabaseCellTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseCellTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
