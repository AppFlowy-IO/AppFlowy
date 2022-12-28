use crate::grid::grid_editor::GridEditorTest;
use async_stream::stream;
use flowy_grid::entities::{AlterSortParams, CellPathParams, DeleteSortParams};
use flowy_grid::services::sort::SortType;
use flowy_grid::services::view_editor::GridViewChanged;
use futures::stream::StreamExt;
use grid_rev_model::{FieldRevision, SortCondition, SortRevision};
use std::cmp::min;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast::Receiver;

pub enum SortScript {
    InsertSort {
        field_rev: Arc<FieldRevision>,
        condition: SortCondition,
    },
    DeleteSort {
        field_rev: Arc<FieldRevision>,
        sort_id: String,
    },
    AssertCellContentOrder {
        field_id: String,
        orders: Vec<&'static str>,
    },
    UpdateTextCell {
        row_id: String,
        text: String,
    },
    AssertSortChanged {
        old_row_orders: Vec<&'static str>,
        new_row_orders: Vec<&'static str>,
    },
    Wait {
        millis: u64,
    },
}

pub struct GridSortTest {
    inner: GridEditorTest,
    pub current_sort_rev: Option<SortRevision>,
    recv: Option<Receiver<GridViewChanged>>,
}

impl GridSortTest {
    pub async fn new() -> Self {
        let editor_test = GridEditorTest::new_table().await;
        Self {
            inner: editor_test,
            current_sort_rev: None,
            recv: None,
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
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id).await.unwrap());
                let params = AlterSortParams {
                    view_id: self.view_id.clone(),
                    field_id: field_rev.id.clone(),
                    sort_id: None,
                    field_type: field_rev.ty,
                    condition: condition.into(),
                };
                let sort_rev = self.editor.create_or_update_sort(params).await.unwrap();
                self.current_sort_rev = Some(sort_rev);
            }
            SortScript::DeleteSort { field_rev, sort_id } => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id).await.unwrap());
                let params = DeleteSortParams {
                    view_id: self.view_id.clone(),
                    sort_type: SortType::from(&field_rev),
                    sort_id,
                };
                self.editor.delete_sort(params).await.unwrap();
                self.current_sort_rev = None;
            }
            SortScript::AssertCellContentOrder { field_id, orders } => {
                let mut cells = vec![];
                let rows = self.editor.get_grid(&self.view_id).await.unwrap().rows;
                for row in rows {
                    let params = CellPathParams {
                        view_id: self.view_id.clone(),
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
            SortScript::UpdateTextCell { row_id, text } => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id).await.unwrap());
                self.update_text_cell(row_id, &text).await;
            }
            SortScript::AssertSortChanged {
                new_row_orders,
                old_row_orders,
            } => {
                if let Some(receiver) = self.recv.take() {
                    assert_sort_changed(
                        receiver,
                        new_row_orders.into_iter().map(|order| order.to_owned()).collect(),
                        old_row_orders.into_iter().map(|order| order.to_owned()).collect(),
                    )
                    .await;
                }
            }
            SortScript::Wait { millis } => {
                tokio::time::sleep(Duration::from_millis(millis)).await;
            }
        }
    }
}

async fn assert_sort_changed(
    mut receiver: Receiver<GridViewChanged>,
    new_row_orders: Vec<String>,
    old_row_orders: Vec<String>,
) {
    let stream = stream! {
       loop {
        tokio::select! {
            changed = receiver.recv() => yield changed.unwrap(),
            _ = tokio::time::sleep(Duration::from_secs(2)) => break,
        };
        }
    };

    stream
        .for_each(|changed| async {
            match changed {
                GridViewChanged::ReorderAllRowsNotification(_changed) => {}
                GridViewChanged::ReorderSingleRowNotification(changed) => {
                    let mut old_row_orders = old_row_orders.clone();
                    let old = old_row_orders.remove(changed.old_index);
                    old_row_orders.insert(changed.new_index, old);
                    assert_eq!(old_row_orders, new_row_orders);
                }
                _ => {}
            }
        })
        .await;
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
