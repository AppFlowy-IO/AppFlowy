use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{AlterSortParams, CellPathParams, DeleteSortParams};
use grid_rev_model::SortRevision;

pub enum SortScript {
    InsertSort {
        params: AlterSortParams,
    },
    DeleteSort {
        params: DeleteSortParams,
    },
    AssertTextOrder {
        field_id: String,
        orders: Vec<&'static str>,
    },
}

pub struct GridSortTest {
    inner: GridEditorTest,
    pub current_sort_rev: Option<SortRevision>,
}

impl GridSortTest {
    pub async fn new() -> Self {
        let editor_test = GridEditorTest::new_table().await;
        Self {
            inner: editor_test,
            current_sort_rev: None,
        }
    }
    pub async fn run_scripts(&mut self, scripts: Vec<SortScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: SortScript) {
        match script {
            SortScript::InsertSort { params } => {
                let sort_rev = self.editor.create_or_update_sort(params).await.unwrap();
                self.current_sort_rev = Some(sort_rev);
            }
            SortScript::DeleteSort { params } => {
                //
                self.editor.delete_sort(params).await.unwrap();
            }
            SortScript::AssertTextOrder { field_id, orders } => {
                let mut cells = vec![];
                let rows = self.editor.get_grid(&self.grid_id).await.unwrap().rows;
                for row in rows {
                    let params = CellPathParams {
                        view_id: self.grid_id.clone(),
                        field_id: field_id.clone(),
                        row_id: row.id,
                    };
                    let cell = self.editor.get_cell_display_str(&params).await;
                    cells.push(cell);
                }
                assert_eq!(cells, orders)
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
