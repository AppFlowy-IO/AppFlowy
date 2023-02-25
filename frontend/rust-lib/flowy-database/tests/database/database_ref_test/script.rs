use crate::database::database_editor::DatabaseEditorTest;
use flowy_database::services::persistence::database_ref::DatabaseInfo;
use std::collections::HashMap;

pub enum DatabaseRefScript {
  LinkGridToDatabase { database_id: String },
  LinkBoardToDatabase { database_id: String },
  CreateNewGrid,
  AssertNumberOfDatabase { expected: usize },
}

pub struct DatabaseRefTest {
  inner: DatabaseEditorTest,
}

impl DatabaseRefTest {
  pub async fn new() -> Self {
    let inner = DatabaseEditorTest::new_grid().await;
    Self { inner }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<DatabaseRefScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn all_databases(&self) -> Vec<DatabaseInfo> {
    self
      .inner
      .sdk
      .database_manager
      .get_databases()
      .await
      .unwrap()
  }

  pub async fn run_script(&mut self, script: DatabaseRefScript) {
    match script {
      DatabaseRefScript::LinkGridToDatabase { database_id } => {
        let mut ext = HashMap::new();
        ext.insert("database_id".to_owned(), database_id);
        self
          .inner
          .sdk
          .folder_manager
          .create_test_grid_view(&self.inner.app_id, "test link grid", ext)
          .await;
      },
      DatabaseRefScript::LinkBoardToDatabase { database_id } => {
        let mut ext = HashMap::new();
        ext.insert("database_id".to_owned(), database_id);
        self
          .inner
          .sdk
          .folder_manager
          .create_test_board_view(&self.inner.app_id, "test link board", ext)
          .await;
      },
      DatabaseRefScript::CreateNewGrid => {
        self
          .inner
          .sdk
          .folder_manager
          .create_test_grid_view(&self.inner.app_id, "Create test grid", HashMap::new())
          .await;
      },
      DatabaseRefScript::AssertNumberOfDatabase { expected } => {
        let databases = self.all_databases().await;
        assert_eq!(databases.len(), expected);
      },
    }
  }
}
