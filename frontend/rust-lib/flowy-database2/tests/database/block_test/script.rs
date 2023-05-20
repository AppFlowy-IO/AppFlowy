use crate::database::database_editor::DatabaseEditorTest;
use flowy_database2::entities::CreateRowParams;

pub enum RowScript {
  CreateEmptyRow,
  AssertRowCount(usize),
}

pub struct DatabaseRowTest {
  inner: DatabaseEditorTest,
}

impl DatabaseRowTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self { inner: editor_test }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<RowScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: RowScript) {
    match script {
      RowScript::CreateEmptyRow => {
        let params = CreateRowParams {
          view_id: self.view_id.clone(),
          start_row_id: None,
          group_id: None,
          cell_data_by_field_id: None,
        };
        let row_order = self.editor.create_row(params).await.unwrap().unwrap();
        self
          .row_by_row_id
          .insert(row_order.id.to_string(), row_order.into());
        self.rows = self.get_rows().await;
      },
      RowScript::AssertRowCount(expected_row_count) => {
        assert_eq!(expected_row_count, self.rows.len());
      },
    }
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
