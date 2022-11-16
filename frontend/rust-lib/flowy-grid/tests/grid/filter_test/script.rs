#![cfg_attr(rustfmt, rustfmt::skip)]
#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_imports)]

use bytes::Bytes;
use futures::TryFutureExt;
use flowy_grid::entities::{CreateFilterParams, CreateFilterPayloadPB, DeleteFilterParams, GridLayout, GridSettingChangesetParams, GridSettingPB, RowPB, TextFilterCondition, FieldType, NumberFilterCondition, CheckboxFilterCondition, DateFilterCondition, DateFilterContent, SelectOptionCondition, TextFilterPB, NumberFilterPB, CheckboxFilterPB, DateFilterPB, SelectOptionFilterPB};
use flowy_grid::services::field::SelectOptionIds;
use flowy_grid::services::setting::GridSettingChangesetBuilder;
use grid_rev_model::{FieldRevision, FieldTypeRevision};
use flowy_grid::services::filter::FilterType;
use crate::grid::grid_editor::GridEditorTest;

pub enum FilterScript {
    InsertFilter {
        payload: CreateFilterPayloadPB,
    },
    CreateTextFilter {
        condition: TextFilterCondition,
        content: String,
    },
    CreateNumberFilter {
        condition: NumberFilterCondition,
        content: String,
    },
    CreateCheckboxFilter {
        condition: CheckboxFilterCondition,
    },
    CreateDateFilter{
        condition: DateFilterCondition,
        start: Option<i64>,
        end: Option<i64>,
        timestamp: Option<i64>,
    },
    CreateMultiSelectFilter {
        condition: SelectOptionCondition,
        option_ids: Vec<String>,
    },
    CreateSingleSelectFilter {
        condition: SelectOptionCondition,
        option_ids: Vec<String>,
    },
    AssertFilterCount {
        count: i32,
    },
    DeleteFilter {
        filter_id: String,
        filter_type: FilterType,
    },
    AssertFilterContent {
        filter_type: FilterType,
        condition: u32,
        content: String
    },
    AssertNumberOfRows{
        expected: usize,
    },
    #[allow(dead_code)]
    AssertGridSetting {
        expected_setting: GridSettingPB,
    },
}

pub struct GridFilterTest {
    inner: GridEditorTest,
}

impl GridFilterTest {
    pub async fn new() -> Self {
        let editor_test =  GridEditorTest::new_table().await;
        Self {
            inner: editor_test
        }
    }

    pub async fn run_scripts(&mut self, scripts: Vec<FilterScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: FilterScript) {
        match script {
            FilterScript::InsertFilter { payload } => {
                self.insert_filter(payload).await;
            }
            FilterScript::CreateTextFilter { condition, content} => {

                let field_rev = self.get_field_rev(FieldType::RichText);
                let text_filter= TextFilterPB {
                    condition,
                    content
                };
                let payload =
                    CreateFilterPayloadPB::new(field_rev, text_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateNumberFilter {condition, content} => {
                let field_rev = self.get_field_rev(FieldType::Number);
                let number_filter = NumberFilterPB {
                    condition,
                    content
                };
                let payload =
                    CreateFilterPayloadPB::new(field_rev, number_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateCheckboxFilter {condition} => {
                let field_rev = self.get_field_rev(FieldType::Checkbox);
                let checkbox_filter = CheckboxFilterPB {
                    condition
                };
                let payload =
                    CreateFilterPayloadPB::new(field_rev, checkbox_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateDateFilter { condition, start, end, timestamp} => {
                let field_rev = self.get_field_rev(FieldType::DateTime);
                let date_filter = DateFilterPB {
                    condition,
                    start,
                    end,
                    timestamp
                };

                let payload =
                    CreateFilterPayloadPB::new(field_rev, date_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateMultiSelectFilter { condition, option_ids} => {
                let field_rev = self.get_field_rev(FieldType::MultiSelect);
                let filter = SelectOptionFilterPB { condition, option_ids };
                let payload =
                    CreateFilterPayloadPB::new(field_rev, filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateSingleSelectFilter { condition, option_ids} => {
                let field_rev = self.get_field_rev(FieldType::SingleSelect);
                let filter = SelectOptionFilterPB { condition, option_ids };
                let payload =
                    CreateFilterPayloadPB::new(field_rev, filter);
                self.insert_filter(payload).await;
            }
            FilterScript::AssertFilterCount { count } => {
                let filters = self.editor.get_all_filters().await.unwrap();
                assert_eq!(count as usize, filters.len());
            }
            FilterScript::AssertFilterContent { filter_type: filter_id, condition, content} => {
                let filter = self.editor.get_filters(filter_id).await.unwrap().pop().unwrap();
                assert_eq!(&filter.content, &content);
                assert_eq!(filter.condition as u32, condition);

            }
            FilterScript::DeleteFilter {  filter_id, filter_type } => {
                let params = DeleteFilterParams { filter_type, filter_id };
                let _ = self.editor.delete_filter(params).await.unwrap();
            }
            FilterScript::AssertGridSetting { expected_setting } => {
                let setting = self.editor.get_setting().await.unwrap();
                assert_eq!(expected_setting, setting);
            }
            FilterScript::AssertNumberOfRows { expected } => {
                //
                let grid = self.editor.get_grid().await.unwrap();
                let rows = grid.blocks.into_iter().map(|block| block.rows).flatten().collect::<Vec<RowPB>>();
                assert_eq!(rows.len(), expected);
            }
        }
    }

    async fn insert_filter(&self, payload: CreateFilterPayloadPB) {
        let params: CreateFilterParams = payload.try_into().unwrap();
        let _ = self.editor.create_filter(params).await.unwrap();
    }
}


impl std::ops::Deref for GridFilterTest {
    type Target = GridEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for GridFilterTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
