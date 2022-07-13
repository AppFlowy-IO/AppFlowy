use crate::grid::grid_editor::GridEditorTest;
use flowy_grid::entities::RowInfo;
use flowy_grid::services::row::{CreateRowRevisionBuilder, CreateRowRevisionPayload};
use flowy_grid_data_model::revision::{
    FieldRevision, GridBlockMetaRevision, GridBlockMetaRevisionChangeset, RowMetaChangeset, RowRevision,
};
use std::sync::Arc;

pub enum RowScript {
    CreateEmptyRow,
    CreateRow {
        payload: CreateRowRevisionPayload,
    },
    UpdateRow {
        changeset: RowMetaChangeset,
    },
    AssertRow {
        expected_row: RowRevision,
    },
    DeleteRows {
        row_ids: Vec<String>,
    },
    AssertRowCount(usize),
    CreateBlock {
        block: GridBlockMetaRevision,
    },
    UpdateBlock {
        changeset: GridBlockMetaRevisionChangeset,
    },
    AssertBlockCount(usize),
    AssertBlock {
        block_index: usize,
        row_count: i32,
        start_row_index: i32,
    },
    AssertBlockEqual {
        block_index: usize,
        block: GridBlockMetaRevision,
    },
}

pub struct GridRowTest {
    inner: GridEditorTest,
}

impl GridRowTest {
    pub async fn new() -> Self {
        let editor_test = GridEditorTest::new().await;
        Self { inner: editor_test }
    }

    pub fn field_revs(&self) -> &Vec<Arc<FieldRevision>> {
        &self.field_revs
    }

    pub fn last_row(&self) -> Option<RowRevision> {
        self.row_revs.last().map(|a| a.clone().as_ref().clone())
    }

    pub async fn run_scripts(&mut self, scripts: Vec<RowScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub fn builder(&self) -> CreateRowRevisionBuilder {
        CreateRowRevisionBuilder::new(&self.field_revs)
    }

    pub async fn run_script(&mut self, script: RowScript) {
        match script {
            RowScript::CreateEmptyRow => {
                let row_order = self.editor.create_row(None).await.unwrap();
                self.row_order_by_row_id
                    .insert(row_order.row_id().to_owned(), row_order);
                self.row_revs = self.get_row_revs().await;
                self.block_meta_revs = self.editor.get_block_meta_revs().await.unwrap();
            }
            RowScript::CreateRow { payload: context } => {
                let row_orders = self.editor.insert_rows(vec![context]).await.unwrap();
                for row_order in row_orders {
                    self.row_order_by_row_id
                        .insert(row_order.row_id().to_owned(), row_order);
                }
                self.row_revs = self.get_row_revs().await;
                self.block_meta_revs = self.editor.get_block_meta_revs().await.unwrap();
            }
            RowScript::UpdateRow { changeset: change } => self.editor.update_row(change).await.unwrap(),
            RowScript::DeleteRows { row_ids } => {
                let row_orders = row_ids
                    .into_iter()
                    .map(|row_id| self.row_order_by_row_id.get(&row_id).unwrap().clone())
                    .collect::<Vec<RowInfo>>();

                self.editor.delete_rows(row_orders).await.unwrap();
                self.row_revs = self.get_row_revs().await;
                self.block_meta_revs = self.editor.get_block_meta_revs().await.unwrap();
            }
            RowScript::AssertRow { expected_row } => {
                let row = &*self
                    .row_revs
                    .iter()
                    .find(|row| row.id == expected_row.id)
                    .cloned()
                    .unwrap();
                assert_eq!(&expected_row, row);
            }
            RowScript::AssertRowCount(expected_row_count) => {
                assert_eq!(expected_row_count, self.row_revs.len());
            }
            RowScript::CreateBlock { block } => {
                self.editor.create_block(block).await.unwrap();
                self.block_meta_revs = self.editor.get_block_meta_revs().await.unwrap();
            }
            RowScript::UpdateBlock { changeset: change } => {
                self.editor.update_block(change).await.unwrap();
            }
            RowScript::AssertBlockCount(count) => {
                assert_eq!(self.editor.get_block_meta_revs().await.unwrap().len(), count);
            }
            RowScript::AssertBlock {
                block_index,
                row_count,
                start_row_index,
            } => {
                assert_eq!(self.block_meta_revs[block_index].row_count, row_count);
                assert_eq!(self.block_meta_revs[block_index].start_row_index, start_row_index);
            }
            RowScript::AssertBlockEqual { block_index, block } => {
                let blocks = self.editor.get_block_meta_revs().await.unwrap();
                let compared_block = blocks[block_index].clone();
                assert_eq!(compared_block, Arc::new(block));
            }
        }
    }
}

impl std::ops::Deref for GridRowTest {
    type Target = GridEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for GridRowTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
