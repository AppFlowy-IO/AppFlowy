use crate::grid::block_test::script::RowScript::{AssertCell, CreateRow};
use crate::grid::block_test::util::GridRowTestBuilder;
use crate::grid::grid_editor::GridEditorTest;

use flowy_grid::entities::{CreateRowParams, FieldType, GridCellIdParams, GridLayout, RowPB};
use flowy_grid::services::field::*;
use flowy_grid_data_model::revision::{
    GridBlockMetaRevision, GridBlockMetaRevisionChangeset, RowChangeset, RowRevision,
};
use std::collections::HashMap;
use std::sync::Arc;
use strum::IntoEnumIterator;

pub enum RowScript {
    CreateEmptyRow,
    CreateRow {
        row_rev: RowRevision,
    },
    UpdateRow {
        changeset: RowChangeset,
    },
    AssertRow {
        expected_row: RowRevision,
    },
    DeleteRows {
        row_ids: Vec<String>,
    },
    AssertCell {
        row_id: String,
        field_id: String,
        field_type: FieldType,
        expected: String,
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
        let editor_test = GridEditorTest::new_table().await;
        Self { inner: editor_test }
    }

    pub fn last_row(&self) -> Option<RowRevision> {
        self.row_revs.last().map(|a| a.clone().as_ref().clone())
    }

    pub async fn run_scripts(&mut self, scripts: Vec<RowScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub fn row_builder(&self) -> GridRowTestBuilder {
        GridRowTestBuilder::new(self.block_id(), &self.field_revs)
    }

    pub async fn run_script(&mut self, script: RowScript) {
        match script {
            RowScript::CreateEmptyRow => {
                let params = CreateRowParams {
                    grid_id: self.editor.grid_id.clone(),
                    start_row_id: None,
                    group_id: None,
                    layout: GridLayout::Table,
                };
                let row_order = self.editor.create_row(params).await.unwrap();
                self.row_order_by_row_id
                    .insert(row_order.row_id().to_owned(), row_order);
                self.row_revs = self.get_row_revs().await;
                self.block_meta_revs = self.editor.get_block_meta_revs().await.unwrap();
            }
            RowScript::CreateRow { row_rev } => {
                let row_orders = self.editor.insert_rows(vec![row_rev]).await.unwrap();
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
                    .collect::<Vec<RowPB>>();

                self.editor.delete_rows(row_orders).await.unwrap();
                self.row_revs = self.get_row_revs().await;
                self.block_meta_revs = self.editor.get_block_meta_revs().await.unwrap();
            }
            RowScript::AssertCell {
                row_id,
                field_id,
                field_type,
                expected,
            } => {
                let id = GridCellIdParams {
                    grid_id: self.grid_id.clone(),
                    field_id,
                    row_id,
                };
                self.compare_cell_content(id, field_type, expected).await;
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

    async fn compare_cell_content(&self, cell_id: GridCellIdParams, field_type: FieldType, expected: String) {
        match field_type {
            FieldType::RichText => {
                let cell_data = self
                    .editor
                    .get_cell_bytes(&cell_id)
                    .await
                    .unwrap()
                    .parser::<TextCellDataParser>()
                    .unwrap();

                assert_eq!(cell_data.as_ref(), &expected);
            }
            FieldType::Number => {
                let field_rev = self.editor.get_field_rev(&cell_id.field_id).await.unwrap();
                let number_type_option = field_rev
                    .get_type_option_entry::<NumberTypeOptionPB>(FieldType::Number.into())
                    .unwrap();
                let cell_data = self
                    .editor
                    .get_cell_bytes(&cell_id)
                    .await
                    .unwrap()
                    .custom_parser(NumberCellCustomDataParser(number_type_option.format))
                    .unwrap();
                assert_eq!(cell_data.to_string(), expected);
            }
            FieldType::DateTime => {
                let cell_data = self
                    .editor
                    .get_cell_bytes(&cell_id)
                    .await
                    .unwrap()
                    .parser::<DateCellDataParser>()
                    .unwrap();

                assert_eq!(cell_data.date, expected);
            }
            FieldType::SingleSelect => {
                let cell_data = self
                    .editor
                    .get_cell_bytes(&cell_id)
                    .await
                    .unwrap()
                    .parser::<SelectOptionCellDataParser>()
                    .unwrap();
                let select_option = cell_data.select_options.first().unwrap();
                assert_eq!(select_option.name, expected);
            }
            FieldType::MultiSelect => {
                let cell_data = self
                    .editor
                    .get_cell_bytes(&cell_id)
                    .await
                    .unwrap()
                    .parser::<SelectOptionCellDataParser>()
                    .unwrap();

                let s = cell_data
                    .select_options
                    .into_iter()
                    .map(|option| option.name)
                    .collect::<Vec<String>>()
                    .join(SELECTION_IDS_SEPARATOR);

                assert_eq!(s, expected);
            }

            FieldType::Checkbox => {
                let cell_data = self
                    .editor
                    .get_cell_bytes(&cell_id)
                    .await
                    .unwrap()
                    .parser::<CheckboxCellDataParser>()
                    .unwrap();
                assert_eq!(cell_data.to_string(), expected);
            }
            FieldType::URL => {
                let cell_data = self
                    .editor
                    .get_cell_bytes(&cell_id)
                    .await
                    .unwrap()
                    .parser::<URLCellDataParser>()
                    .unwrap();

                assert_eq!(cell_data.content, expected);
                // assert_eq!(cell_data.url, expected);
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

pub struct CreateRowScriptBuilder<'a> {
    builder: GridRowTestBuilder<'a>,
    data_by_field_type: HashMap<FieldType, CellTestData>,
    output_by_field_type: HashMap<FieldType, CellTestOutput>,
}

impl<'a> CreateRowScriptBuilder<'a> {
    pub fn new(test: &'a GridRowTest) -> Self {
        Self {
            builder: test.row_builder(),
            data_by_field_type: HashMap::new(),
            output_by_field_type: HashMap::new(),
        }
    }

    pub fn insert(&mut self, field_type: FieldType, input: &str, expected: &str) {
        self.data_by_field_type.insert(
            field_type,
            CellTestData {
                input: input.to_string(),
                expected: expected.to_owned(),
            },
        );
    }

    pub fn insert_single_select_cell<F>(&mut self, f: F, expected: &str)
    where
        F: Fn(Vec<SelectOptionPB>) -> SelectOptionPB,
    {
        let field_id = self.builder.insert_single_select_cell(f);
        self.output_by_field_type.insert(
            FieldType::SingleSelect,
            CellTestOutput {
                field_id,
                expected: expected.to_owned(),
            },
        );
    }

    pub fn insert_multi_select_cell<F>(&mut self, f: F, expected: &str)
    where
        F: Fn(Vec<SelectOptionPB>) -> Vec<SelectOptionPB>,
    {
        let field_id = self.builder.insert_multi_select_cell(f);
        self.output_by_field_type.insert(
            FieldType::MultiSelect,
            CellTestOutput {
                field_id,
                expected: expected.to_owned(),
            },
        );
    }

    pub fn build(mut self) -> Vec<RowScript> {
        let mut scripts = vec![];
        let output_by_field_type = &mut self.output_by_field_type;

        for field_type in FieldType::iter() {
            let field_type: FieldType = field_type;
            if let Some(data) = self.data_by_field_type.get(&field_type) {
                let field_id = match field_type {
                    FieldType::RichText => self.builder.insert_text_cell(&data.input),
                    FieldType::Number => self.builder.insert_number_cell(&data.input),
                    FieldType::DateTime => self.builder.insert_date_cell(&data.input),
                    FieldType::Checkbox => self.builder.insert_checkbox_cell(&data.input),
                    FieldType::URL => self.builder.insert_url_cell(&data.input),
                    _ => "".to_owned(),
                };

                if !field_id.is_empty() {
                    output_by_field_type.insert(
                        field_type,
                        CellTestOutput {
                            field_id,
                            expected: data.expected.clone(),
                        },
                    );
                }
            }
        }

        let row_rev = self.builder.build();
        let row_id = row_rev.id.clone();
        scripts.push(CreateRow { row_rev });

        for field_type in FieldType::iter() {
            if let Some(data) = output_by_field_type.get(&field_type) {
                let script = AssertCell {
                    row_id: row_id.clone(),
                    field_id: data.field_id.clone(),
                    field_type,
                    expected: data.expected.clone(),
                };
                scripts.push(script);
            }
        }
        scripts
    }
}

pub struct CellTestData {
    pub input: String,
    pub expected: String,
}

struct CellTestOutput {
    field_id: String,
    expected: String,
}
