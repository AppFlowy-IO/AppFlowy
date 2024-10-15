use collab_database::rows::RowId;
use tokio::sync::broadcast::Receiver;

use flowy_database2::entities::UpdateCalculationChangesetPB;
use flowy_database2::services::database_view::DatabaseViewChanged;

use crate::database::database_editor::DatabaseEditorTest;

pub struct DatabaseCalculationTest {
  inner: DatabaseEditorTest,
  recv: Option<Receiver<DatabaseViewChanged>>,
}

impl DatabaseCalculationTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self {
      inner: editor_test,
      recv: None,
    }
  }

  pub fn view_id(&self) -> String {
    self.view_id.clone()
  }

  pub async fn insert_calculation(&mut self, payload: UpdateCalculationChangesetPB) {
    self.recv = Some(
      self
        .editor
        .subscribe_view_changed(&self.view_id())
        .await
        .unwrap(),
    );
    self.editor.update_calculation(payload).await.unwrap();
  }

  pub async fn assert_calculation_float_value(&mut self, expected: f64) {
    let calculations = self.editor.get_all_calculations(&self.view_id()).await;
    let calculation = calculations.items.first().unwrap();
    assert_eq!(calculation.value, format!("{:.5}", expected));
  }

  pub async fn assert_calculation_value(&mut self, expected: &str) {
    let calculations = self.editor.get_all_calculations(&self.view_id()).await;
    let calculation = calculations.items.first().unwrap();
    assert_eq!(calculation.value, expected);
  }

  pub async fn duplicate_row(&self, row_id: &RowId) {
    self
      .editor
      .duplicate_row(&self.view_id, row_id)
      .await
      .unwrap();
  }
}

impl std::ops::Deref for DatabaseCalculationTest {
  type Target = DatabaseEditorTest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::ops::DerefMut for DatabaseCalculationTest {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.inner
  }
}
