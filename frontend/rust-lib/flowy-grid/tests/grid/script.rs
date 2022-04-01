use bytes::Bytes;
use flowy_grid::services::field::*;
use flowy_grid::services::grid_editor::{ClientGridEditor, GridPadBuilder};
use flowy_grid::services::row::CreateRowMetaPayload;
use flowy_grid_data_model::entities::{
    BuildGridContext, CellMetaChangeset, CreateFieldParams, Field, FieldChangesetParams, FieldMeta, FieldType,
    GridBlockMeta, GridBlockMetaChangeset, RowMeta, RowMetaChangeset, RowOrder, TypeOptionDataEntry,
};
use flowy_revision::REVISION_WRITE_INTERVAL_IN_MILLIS;
use flowy_sync::client_grid::GridBuilder;
use flowy_test::helper::ViewTest;
use flowy_test::FlowySDKTest;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use strum::EnumCount;
use tokio::time::sleep;

pub enum EditorScript {
    CreateField {
        params: CreateFieldParams,
    },
    UpdateField {
        changeset: FieldChangesetParams,
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
        block: GridBlockMeta,
    },
    UpdateBlock {
        changeset: GridBlockMetaChangeset,
    },
    AssertBlockCount(usize),
    AssertBlock {
        block_index: usize,
        row_count: i32,
        start_row_index: i32,
    },
    AssertBlockEqual {
        block_index: usize,
        block: GridBlockMeta,
    },
    CreateEmptyRow,
    CreateRow {
        context: CreateRowMetaPayload,
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
        is_err: bool,
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
    pub grid_blocks: Vec<GridBlockMeta>,
    pub row_metas: Vec<Arc<RowMeta>>,
    pub field_count: usize,

    pub row_order_by_row_id: HashMap<String, RowOrder>,
}

impl GridEditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::default();
        let _ = sdk.init_user().await;
        let build_context = make_template_1_grid();
        let view_data: Bytes = build_context.try_into().unwrap();
        let test = ViewTest::new_grid_view(&sdk, view_data.to_vec()).await;
        let editor = sdk.grid_manager.open_grid(&test.view.id).await.unwrap();
        let field_metas = editor.get_field_metas(None).await.unwrap();
        let grid_blocks = editor.get_block_metas().await.unwrap();
        let row_metas = get_row_metas(&editor).await;

        let grid_id = test.view.id;
        Self {
            sdk,
            grid_id,
            editor,
            field_metas,
            grid_blocks,
            row_metas,
            field_count: FieldType::COUNT,
            row_order_by_row_id: HashMap::default(),
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
            EditorScript::CreateField { params } => {
                if !self.editor.contain_field(&params.field.id).await {
                    self.field_count += 1;
                }

                self.editor.create_field(params).await.unwrap();
                self.field_metas = self.editor.get_field_metas(None).await.unwrap();
                assert_eq!(self.field_count, self.field_metas.len());
            }
            EditorScript::UpdateField { changeset: change } => {
                self.editor.update_field(change).await.unwrap();
                self.field_metas = self.editor.get_field_metas(None).await.unwrap();
            }
            EditorScript::DeleteField { field_meta } => {
                if self.editor.contain_field(&field_meta.id).await {
                    self.field_count -= 1;
                }

                self.editor.delete_field(&field_meta.id).await.unwrap();
                self.field_metas = self.editor.get_field_metas(None).await.unwrap();
                assert_eq!(self.field_count, self.field_metas.len());
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
                self.grid_blocks = self.editor.get_block_metas().await.unwrap();
            }
            EditorScript::UpdateBlock { changeset: change } => {
                self.editor.update_block(change).await.unwrap();
            }
            EditorScript::AssertBlockCount(count) => {
                assert_eq!(self.editor.get_block_metas().await.unwrap().len(), count);
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
                let blocks = self.editor.get_block_metas().await.unwrap();
                let compared_block = blocks[block_index].clone();
                assert_eq!(compared_block, block);
            }
            EditorScript::CreateEmptyRow => {
                let row_order = self.editor.create_row(None).await.unwrap();
                self.row_order_by_row_id.insert(row_order.row_id.clone(), row_order);
                self.row_metas = self.get_row_metas().await;
                self.grid_blocks = self.editor.get_block_metas().await.unwrap();
            }
            EditorScript::CreateRow { context } => {
                let row_orders = self.editor.insert_rows(vec![context]).await.unwrap();
                for row_order in row_orders {
                    self.row_order_by_row_id.insert(row_order.row_id.clone(), row_order);
                }
                self.row_metas = self.get_row_metas().await;
                self.grid_blocks = self.editor.get_block_metas().await.unwrap();
            }
            EditorScript::UpdateRow { changeset: change } => self.editor.update_row(change).await.unwrap(),
            EditorScript::DeleteRow { row_ids } => {
                let row_orders = row_ids
                    .into_iter()
                    .map(|row_id| self.row_order_by_row_id.get(&row_id).unwrap().clone())
                    .collect::<Vec<RowOrder>>();

                self.editor.delete_rows(row_orders).await.unwrap();
                self.row_metas = self.get_row_metas().await;
                self.grid_blocks = self.editor.get_block_metas().await.unwrap();
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
            EditorScript::UpdateCell { changeset, is_err } => {
                let result = self.editor.update_cell(changeset).await;
                if is_err {
                    assert!(result.is_err())
                } else {
                    let _ = result.unwrap();
                    self.row_metas = self.get_row_metas().await;
                }
            }
            EditorScript::AssertRowCount(count) => {
                assert_eq!(self.row_metas.len(), count);
            }
            EditorScript::AssertGridMetaPad => {
                sleep(Duration::from_millis(2 * REVISION_WRITE_INTERVAL_IN_MILLIS)).await;
                let mut grid_rev_manager = grid_manager.make_grid_rev_manager(&self.grid_id, pool.clone()).unwrap();
                let grid_pad = grid_rev_manager.load::<GridPadBuilder>(None).await.unwrap();
                println!("{}", grid_pad.delta_str());
            }
        }
    }

    async fn get_row_metas(&self) -> Vec<Arc<RowMeta>> {
        get_row_metas(&self.editor).await
    }
}

async fn get_row_metas(editor: &Arc<ClientGridEditor>) -> Vec<Arc<RowMeta>> {
    editor
        .get_block_meta_data_vec(None)
        .await
        .unwrap()
        .pop()
        .unwrap()
        .row_metas
}

pub fn create_text_field(grid_id: &str) -> (CreateFieldParams, FieldMeta) {
    let field_meta = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .build();

    let cloned_field_meta = field_meta.clone();

    let type_option_data = field_meta
        .get_type_option_entry::<RichTextTypeOption>(None)
        .unwrap()
        .protobuf_bytes()
        .to_vec();

    let field = Field {
        id: field_meta.id,
        name: field_meta.name,
        desc: field_meta.desc,
        field_type: field_meta.field_type,
        frozen: field_meta.frozen,
        visibility: field_meta.visibility,
        width: field_meta.width,
    };

    let params = CreateFieldParams {
        grid_id: grid_id.to_owned(),
        field,
        type_option_data,
        start_field_id: None,
    };
    (params, cloned_field_meta)
}

pub fn create_single_select_field(grid_id: &str) -> (CreateFieldParams, FieldMeta) {
    let single_select = SingleSelectTypeOptionBuilder::default()
        .option(SelectOption::new("Done"))
        .option(SelectOption::new("Progress"));

    let field_meta = FieldBuilder::new(single_select).name("Name").visibility(true).build();
    let cloned_field_meta = field_meta.clone();
    let type_option_data = field_meta
        .get_type_option_entry::<SingleSelectTypeOption>(None)
        .unwrap()
        .protobuf_bytes()
        .to_vec();

    let field = Field {
        id: field_meta.id,
        name: field_meta.name,
        desc: field_meta.desc,
        field_type: field_meta.field_type,
        frozen: field_meta.frozen,
        visibility: field_meta.visibility,
        width: field_meta.width,
    };

    let params = CreateFieldParams {
        grid_id: grid_id.to_owned(),
        field,
        type_option_data,
        start_field_id: None,
    };
    (params, cloned_field_meta)
}

fn make_template_1_grid() -> BuildGridContext {
    let text_field = FieldBuilder::new(RichTextTypeOptionBuilder::default())
        .name("Name")
        .visibility(true)
        .build();

    // Single Select
    let single_select = SingleSelectTypeOptionBuilder::default()
        .option(SelectOption::new("Live"))
        .option(SelectOption::new("Completed"))
        .option(SelectOption::new("Planned"))
        .option(SelectOption::new("Paused"));
    let single_select_field = FieldBuilder::new(single_select).name("Status").visibility(true).build();

    // MultiSelect
    let multi_select = MultiSelectTypeOptionBuilder::default()
        .option(SelectOption::new("Google"))
        .option(SelectOption::new("Facebook"))
        .option(SelectOption::new("Twitter"));
    let multi_select_field = FieldBuilder::new(multi_select)
        .name("Platform")
        .visibility(true)
        .build();

    // Number
    let number = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
    let number_field = FieldBuilder::new(number).name("Price").visibility(true).build();

    // Date
    let date = DateTypeOptionBuilder::default()
        .date_format(DateFormat::US)
        .time_format(TimeFormat::TwentyFourHour);
    let date_field = FieldBuilder::new(date).name("Time").visibility(true).build();

    // Checkbox
    let checkbox = CheckboxTypeOptionBuilder::default();
    let checkbox_field = FieldBuilder::new(checkbox).name("is done").visibility(true).build();

    GridBuilder::default()
        .add_field(text_field)
        .add_field(single_select_field)
        .add_field(multi_select_field)
        .add_field(number_field)
        .add_field(date_field)
        .add_field(checkbox_field)
        .add_empty_row()
        .add_empty_row()
        .add_empty_row()
        .build()
}
