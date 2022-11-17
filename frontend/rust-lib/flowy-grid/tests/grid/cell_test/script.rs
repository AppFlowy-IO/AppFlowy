use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::CellChangesetPB;

pub enum CellScript {
    UpdateCell { changeset: CellChangesetPB, is_err: bool },
}

pub struct GridCellTest {
    inner: GridEditorTest,
}

impl GridCellTest {
    pub async fn new() -> Self {
        let inner = GridEditorTest::new_table().await;
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
        let rev_manager = self.editor.rev_manager();
        let _cache = rev_manager.revision_cache().await;

        match script {
            CellScript::UpdateCell { changeset, is_err } => {
                let result = self.editor.update_cell_with_changeset(changeset).await;
                if is_err {
                    assert!(result.is_err())
                } else {
                    let _ = result.unwrap();
                    self.row_revs = self.get_row_revs().await;
                }
            } // CellScript::AssertGridRevisionPad => {
              //     sleep(Duration::from_millis(2 * REVISION_WRITE_INTERVAL_IN_MILLIS)).await;
              //     let mut grid_rev_manager = grid_manager.make_grid_rev_manager(&self.grid_id, pool.clone()).unwrap();
              //     let grid_pad = grid_rev_manager.load::<GridPadBuilder>(None).await.unwrap();
              //     println!("{}", grid_pad.delta_str());
              // }
        }
    }
}

impl std::ops::Deref for GridCellTest {
    type Target = GridEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for GridCellTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
