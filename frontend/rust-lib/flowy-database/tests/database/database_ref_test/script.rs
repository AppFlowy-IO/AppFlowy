use crate::database::block_test::util::DatabaseRowTestBuilder;
use crate::database::database_editor::DatabaseEditorTest;
use database_model::RowRevision;
use flowy_database::services::database::DatabaseEditor;
use flowy_database::services::persistence::database_ref::{DatabaseInfo, DatabaseViewRef};
use std::collections::HashMap;
use std::sync::Arc;

pub enum DatabaseRefScript {
  LinkGridToDatabase {
    database_id: String,
  },
  #[allow(dead_code)]
  LinkBoardToDatabase {
    database_id: String,
  },
  CreateNewGrid,
  CreateRow {
    view_id: String,
    row_rev: RowRevision,
  },
  AssertNumberOfRows {
    view_id: String,
    expected: usize,
  },
  AssertNumberOfDatabase {
    expected: usize,
  },
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

  pub async fn block_id(&self, view_id: &str) -> String {
    let editor = self.get_database_editor(view_id).await;
    let mut block_meta_revs = editor.get_block_meta_revs().await.unwrap();
    let block = block_meta_revs.pop().unwrap();
    block.block_id.clone()
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

  pub async fn all_database_ref_views(&self, database_id: &str) -> Vec<DatabaseViewRef> {
    self
      .inner
      .sdk
      .database_manager
      .get_database_ref_views(database_id)
      .await
      .unwrap()
  }

  async fn get_database_editor(&self, view_id: &str) -> Arc<DatabaseEditor> {
    self
      .inner
      .sdk
      .database_manager
      .open_database_view(&view_id)
      .await
      .unwrap()
  }

  pub async fn row_builder(&self, view_id: &str) -> DatabaseRowTestBuilder {
    let editor = self.get_database_editor(view_id).await;
    let field_revs = editor.get_field_revs(None).await.unwrap();
    DatabaseRowTestBuilder::new(self.block_id(view_id).await, field_revs)
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
      DatabaseRefScript::CreateRow { view_id, row_rev } => {
        let editor = self.get_database_editor(&view_id).await;
        let _ = editor.insert_rows(vec![row_rev]).await.unwrap();
      },
      DatabaseRefScript::AssertNumberOfRows { view_id, expected } => {
        let editor = self.get_database_editor(&view_id).await;
        let rows = editor.get_all_row_revs(&view_id).await.unwrap();
        assert_eq!(rows.len(), expected);
      },
    }
  }
}
