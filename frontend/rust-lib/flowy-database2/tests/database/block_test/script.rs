use crate::database::database_editor::DatabaseEditorTest;
use collab_database::database::gen_row_id;
use collab_database::rows::RowId;

use lib_infra::util::timestamp;

pub enum RowScript {
  CreateEmptyRow,
  UpdateTextCell { row_id: RowId, content: String },
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
        let params = collab_database::rows::CreateRowParams {
          id: gen_row_id(),
          timestamp: timestamp(),
          ..Default::default()
        };
        let row_order = self
          .editor
          .create_row(&self.view_id, None, params)
          .await
          .unwrap()
          .unwrap();
        self
          .row_by_row_id
          .insert(row_order.id.to_string(), row_order.into());
        self.rows = self.get_rows().await;
      },
      RowScript::UpdateTextCell { row_id, content } => {
        self.update_text_cell(row_id, &content).await.unwrap();
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
