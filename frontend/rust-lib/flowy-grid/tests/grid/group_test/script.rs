use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::MoveRowParams;

pub enum GroupScript {
    MoveCard { from_row_id: String, to_row_id: String },
    AssertGroupCount(usize),
}

pub struct GridGroupTest {
    inner: GridEditorTest,
}

impl GridGroupTest {
    pub async fn new() -> Self {
        let editor_test = GridEditorTest::new().await;
        Self { inner: editor_test }
    }

    pub async fn run_scripts(&mut self, scripts: Vec<GroupScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: GroupScript) {
        match script {
            GroupScript::MoveCard { from_row_id, to_row_id } => {
                let params = MoveRowParams {
                    view_id: self.inner.grid_id.clone(),
                    from_row_id,
                    to_row_id,
                };
                let _ = self.editor.move_row(params).await.unwrap();
            }
            GroupScript::AssertGroupCount(count) => {
                //
            }
        }
    }
}

impl std::ops::Deref for GridGroupTest {
    type Target = GridEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for GridGroupTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
