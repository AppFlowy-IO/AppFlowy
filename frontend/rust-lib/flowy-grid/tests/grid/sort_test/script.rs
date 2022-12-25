use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::{AlterSortParams, CellPathParams, DeleteSortParams};
use grid_rev_model::{FieldRevision, SortCondition, SortRevision};
use std::cmp::min;
use std::sync::Arc;

pub enum SortScript {
    InsertSort {
        field_rev: Arc<FieldRevision>,
        condition: SortCondition,
    },
    DeleteSort {
        params: DeleteSortParams,
    },
    AssertCellContentOrder {
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
            SortScript::InsertSort { condition, field_rev } => {
                let params = AlterSortParams {
                    view_id: self.grid_id.clone(),
                    field_id: field_rev.id.clone(),
                    sort_id: None,
                    field_type: field_rev.ty,
                    condition: condition.into(),
                };
                let sort_rev = self.editor.create_or_update_sort(params).await.unwrap();
                self.current_sort_rev = Some(sort_rev);
            }
            SortScript::DeleteSort { params } => {
                //
                self.editor.delete_sort(params).await.unwrap();
            }
            SortScript::AssertCellContentOrder { field_id, orders } => {
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
                if orders.is_empty() {
                    assert_eq!(cells, orders);
                } else {
                    let len = min(cells.len(), orders.len());
                    assert_eq!(cells.split_at(len).0, orders);
                }
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
