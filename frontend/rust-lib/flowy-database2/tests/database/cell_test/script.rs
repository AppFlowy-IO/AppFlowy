use collab_database::rows::RowId;

use flowy_database2::entities::CellChangesetPB;

use crate::database::database_editor::DatabaseEditorTest;

pub enum CellScript {
  UpdateCell {
    changeset: CellChangesetPB,
    is_err: bool,
  },
}

pub struct DatabaseCellTest {
  inner: DatabaseEditorTest,
}

impl DatabaseCellTest {
  pub async fn new() -> Self {
    let inner = DatabaseEditorTest::new_grid().await;
    Self { inner }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<CellScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: CellScript) {
    // let grid_manager = self.sdk.grid_manager.clone();
    // let pool = self.sdk.user_session.db_pool().unwrap();
    // let rev_manager = self.editor.rev_manager();
    // let _cache = rev_manager.revision_cache().await;

    match script {
      CellScript::UpdateCell {
        changeset,
        is_err: _,
      } => {
        self
          .editor
          .update_cell_with_changeset(
            &self.view_id,
            RowId::from(changeset.row_id),
            &changeset.field_id,
            changeset.cell_changeset,
          )
          .await
          .unwrap();
      }, // CellScript::AssertGridRevisionPad => {
         //     sleep(Duration::from_millis(2 * REVISION_WRITE_INTERVAL_IN_MILLIS)).await;
         //     let mut grid_rev_manager = grid_manager.make_grid_rev_manager(&self.grid_id, pool.clone()).unwrap();
         //     let grid_pad = grid_rev_manager.load::<GridPadBuilder>(None).await.unwrap();
         //     println!("{}", grid_pad.delta_str());
         // }
    }
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
