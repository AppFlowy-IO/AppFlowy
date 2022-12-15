use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{AlterSortParams, DeleteSortParams};

pub enum SortScript {
    InsertSort { params: AlterSortParams },
    DeleteSort { params: DeleteSortParams },
    AssertTextOrder { orders: Vec<String> },
}

pub struct GridSortTest {
    inner: GridEditorTest,
}

impl GridSortTest {
    pub async fn new() -> Self {
        let editor_test = GridEditorTest::new_table().await;
        Self { inner: editor_test }
    }
    pub async fn run_scripts(&mut self, scripts: Vec<SortScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: SortScript) {
        match script {
            SortScript::InsertSort { params } => {
                let _ = self.editor.create_or_update_sort(params).await.unwrap();
            }
            SortScript::DeleteSort { params } => {
                //
                self.editor.delete_sort(params).await.unwrap();
            }
            SortScript::AssertTextOrder { orders: _ } => {
                //
            }
        }
    }
}

impl std::ops::Deref for GridSortTest {
    type Target = GridEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for GridSortTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
