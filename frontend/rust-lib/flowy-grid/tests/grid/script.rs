use flowy_grid::services::cell::*;
use flowy_grid::services::field::*;
use flowy_grid::services::grid_editor::{ClientGridEditor, GridPadBuilder};
use flowy_grid::services::row::CreateRowContext;
use flowy_grid_data_model::entities::{
    CellMetaChangeset, FieldChangeset, FieldMeta, FieldType, GridBlock, GridBlockChangeset, RowMeta, RowMetaChangeset,
};
use flowy_sync::REVISION_WRITE_INTERVAL_IN_MILLIS;
use flowy_test::helper::ViewTest;
use flowy_test::FlowySDKTest;
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;

pub enum EditorScript {
    CreateField {
        field_meta: FieldMeta,
    },
    UpdateField {
        changeset: FieldChangeset,
    },
    DeleteField {
        field_meta: FieldMeta,
    },
    AssertFieldCount(usize),
    AssertFieldEqual {
        field_index: usize,
        field_meta: FieldMeta,
    },
    CreateBlock {
        block: GridBlock,
    },
    UpdateBlock {
        changeset: GridBlockChangeset,
    },
    AssertBlockCount(usize),
    AssertBlock {
        block_index: usize,
        row_count: i32,
        start_row_index: i32,
    },
    AssertBlockEqual {
        block_index: usize,
        block: GridBlock,
    },
    CreateEmptyRow,
    CreateRow {
        context: CreateRowContext,
    },
    UpdateRow {
        changeset: RowMetaChangeset,
    },
    AssertRow {
        changeset: RowMetaChangeset,
    },
    DeleteRow {
        row_ids: Vec<String>,
    },
    UpdateCell {
        changeset: CellMetaChangeset,
    },
    AssertRowCount(usize),
    // AssertRowEqual{ row_index: usize, row: RowMeta},
    AssertGridMetaPad,
}

pub struct GridEditorTest {
    pub sdk: FlowySDKTest,
    pub grid_id: String,
    pub editor: Arc<ClientGridEditor>,
    pub field_metas: Vec<FieldMeta>,
    pub grid_blocks: Vec<GridBlock>,
    pub row_metas: Vec<Arc<RowMeta>>,
}

impl GridEditorTest {
    pub async fn new() -> Self {
        Self::with_data("".to_owned()).await
    }

    pub async fn with_data(data: String) -> Self {
        let sdk = FlowySDKTest::default();
        let _ = sdk.init_user().await;
        let test = ViewTest::new_grid_view(&sdk, data).await;
        let editor = sdk.grid_manager.open_grid(&test.view.id).await.unwrap();
        let fields = editor.get_field_metas(None).await.unwrap();
        let grid_blocks = editor.get_blocks().await.unwrap();
        let row_metas = editor.get_row_metas(None).await.unwrap();

        let grid_id = test.view.id;
        Self {
            sdk,
            grid_id,
            editor,
            field_metas: fields,
            grid_blocks,
            row_metas,
        }
    }

    pub async fn run_scripts(&mut self, scripts: Vec<EditorScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: EditorScript) {
        let grid_manager = self.sdk.grid_manager.clone();
        let pool = self.sdk.user_session.db_pool().unwrap();
        let rev_manager = self.editor.rev_manager();
        let _cache = rev_manager.revision_cache().await;

        match script {
            EditorScript::CreateField { field_meta: field } => {
                self.editor.create_field(field).await.unwrap();
                self.field_metas = self.editor.get_field_metas(None).await.unwrap();
            }
            EditorScript::UpdateField { changeset: change } => {
                self.editor.update_field(change).await.unwrap();
                self.field_metas = self.editor.get_field_metas(None).await.unwrap();
            }
            EditorScript::DeleteField { field_meta: field } => {
                self.editor.delete_field(&field.id).await.unwrap();
                self.field_metas = self.editor.get_field_metas(None).await.unwrap();
            }
            EditorScript::AssertFieldCount(count) => {
                assert_eq!(self.editor.get_field_metas(None).await.unwrap().len(), count);
            }

            EditorScript::AssertFieldEqual {
                field_index,
                field_meta,
            } => {
                let field_metas = self.editor.get_field_metas(None).await.unwrap();
                assert_eq!(field_metas[field_index].clone(), field_meta);
            }
            EditorScript::CreateBlock { block } => {
                self.editor.create_block(block).await.unwrap();
                self.grid_blocks = self.editor.get_blocks().await.unwrap();
            }
            EditorScript::UpdateBlock { changeset: change } => {
                self.editor.update_block(change).await.unwrap();
            }
            EditorScript::AssertBlockCount(count) => {
                assert_eq!(self.editor.get_blocks().await.unwrap().len(), count);
            }
            EditorScript::AssertBlock {
                block_index,
                row_count,
                start_row_index,
            } => {
                assert_eq!(self.grid_blocks[block_index].row_count, row_count);
                assert_eq!(self.grid_blocks[block_index].start_row_index, start_row_index);
            }
            EditorScript::AssertBlockEqual { block_index, block } => {
                let blocks = self.editor.get_blocks().await.unwrap();
                let compared_block = blocks[block_index].clone();
                assert_eq!(compared_block, block);
            }
            EditorScript::CreateEmptyRow => {
                self.editor.create_row().await.unwrap();
                self.row_metas = self.editor.get_row_metas(None).await.unwrap();
                self.grid_blocks = self.editor.get_blocks().await.unwrap();
            }
            EditorScript::CreateRow { context } => {
                self.editor.insert_rows(vec![context]).await.unwrap();
                self.row_metas = self.editor.get_row_metas(None).await.unwrap();
                self.grid_blocks = self.editor.get_blocks().await.unwrap();
            }
            EditorScript::UpdateRow { changeset: change } => self.editor.update_row(change).await.unwrap(),
            EditorScript::DeleteRow { row_ids } => {
                self.editor.delete_rows(row_ids).await.unwrap();
                self.row_metas = self.editor.get_row_metas(None).await.unwrap();
                self.grid_blocks = self.editor.get_blocks().await.unwrap();
            }
            EditorScript::AssertRow { changeset } => {
                let row = self.row_metas.iter().find(|row| row.id == changeset.row_id).unwrap();

                if let Some(visibility) = changeset.visibility {
                    assert_eq!(row.visibility, visibility);
                }

                if let Some(height) = changeset.height {
                    assert_eq!(row.height, height);
                }
            }
            EditorScript::UpdateCell { changeset } => {
                self.editor.update_cell(changeset).await.unwrap();
                self.row_metas = self.editor.get_row_metas(None).await.unwrap();
            }
            EditorScript::AssertRowCount(count) => {
                assert_eq!(self.editor.get_rows(None).await.unwrap().len(), count);
            }
            EditorScript::AssertGridMetaPad => {
                sleep(Duration::from_millis(2 * REVISION_WRITE_INTERVAL_IN_MILLIS)).await;
                let mut grid_rev_manager = grid_manager.make_grid_rev_manager(&self.grid_id, pool.clone()).unwrap();
                let grid_pad = grid_rev_manager.load::<GridPadBuilder>(None).await.unwrap();
                println!("{}", grid_pad.delta_str());
            }
        }
    }
}

pub fn create_text_field() -> FieldMeta {
    FieldBuilder::new(RichTextTypeOptionsBuilder::default())
        .name("Name")
        .visibility(true)
        .field_type(FieldType::RichText)
        .build()
}

pub fn create_single_select_field() -> FieldMeta {
    let single_select = SingleSelectTypeOptionsBuilder::default()
        .option(SelectOption::new("Done"))
        .option(SelectOption::new("Progress"));

    FieldBuilder::new(single_select)
        .name("Name")
        .visibility(true)
        .field_type(FieldType::SingleSelect)
        .build()
}
