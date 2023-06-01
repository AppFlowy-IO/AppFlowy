#![cfg_attr(rustfmt, rustfmt::skip)]
#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_imports)]

use std::time::Duration;

use bytes::Bytes;
use collab_database::rows::{Row, RowId};
use futures::TryFutureExt;
use tokio::sync::broadcast::Receiver;

use flowy_database2::entities::{UpdateFilterParams, UpdateFilterPayloadPB, CheckboxFilterConditionPB, CheckboxFilterPB, ChecklistFilterConditionPB, ChecklistFilterPB, DatabaseViewSettingPB, DateFilterConditionPB, DateFilterPB, DeleteFilterParams, FieldType, FilterPB, NumberFilterConditionPB, NumberFilterPB, SelectOptionConditionPB, SelectOptionFilterPB, TextFilterConditionPB, TextFilterPB, SelectOptionPB};
use flowy_database2::services::database_view::DatabaseViewChanged;
use flowy_database2::services::field::SelectOption;
use flowy_database2::services::filter::FilterType;

use crate::database::database_editor::DatabaseEditorTest;

pub struct FilterRowChanged {
    pub(crate) showing_num_of_rows: usize,
    pub(crate) hiding_num_of_rows: usize,
}

pub enum FilterScript {
    UpdateTextCell {
        row_id: RowId,
        text: String,
       changed: Option<FilterRowChanged>,
    },
    UpdateChecklistCell{
        row_id: RowId,
        f: Box<dyn FnOnce(Vec<SelectOptionPB>) -> Vec<String>> ,
    },
    UpdateSingleSelectCell {
        row_id: RowId,
        option_id: String,
        changed: Option<FilterRowChanged>,
    },
    InsertFilter {
        payload: UpdateFilterPayloadPB,
    },
    CreateTextFilter {
        condition: TextFilterConditionPB,
        content: String,
        changed: Option<FilterRowChanged>,
    },
    UpdateTextFilter {
        filter: FilterPB,
        condition: TextFilterConditionPB,
        content: String,
        changed: Option<FilterRowChanged>,
    },
    CreateNumberFilter {
        condition: NumberFilterConditionPB,
        content: String,
        changed: Option<FilterRowChanged>,
    },
    CreateCheckboxFilter {
        condition: CheckboxFilterConditionPB,
        changed: Option<FilterRowChanged>,
    },
    CreateDateFilter{
        condition: DateFilterConditionPB,
        start: Option<i64>,
        end: Option<i64>,
        timestamp: Option<i64>,
        changed: Option<FilterRowChanged>,
    },
    CreateMultiSelectFilter {
        condition: SelectOptionConditionPB,
        option_ids: Vec<String>,
    },
    CreateSingleSelectFilter {
        condition: SelectOptionConditionPB,
        option_ids: Vec<String>,
        changed: Option<FilterRowChanged>,
    },
    CreateChecklistFilter {
        condition: ChecklistFilterConditionPB,
        changed: Option<FilterRowChanged>,
    },
    AssertFilterCount {
        count: i32,
    },
    DeleteFilter {
        filter_id: String,
        filter_type: FilterType,
        changed: Option<FilterRowChanged>,
    },
    AssertFilterContent {
        filter_id: String,
        condition: i64,
        content: String
    },
    AssertNumberOfVisibleRows {
        expected: usize,
    },
    #[allow(dead_code)]
    AssertGridSetting {
        expected_setting: DatabaseViewSettingPB,
    },
    Wait { millisecond: u64 }
}

pub struct DatabaseFilterTest {
    inner: DatabaseEditorTest,
    recv: Option<Receiver<DatabaseViewChanged>>,
}

impl DatabaseFilterTest {
    pub async fn new() -> Self {
        let editor_test =  DatabaseEditorTest::new_grid().await;
        Self {
            inner: editor_test,
            recv: None,
        }
    }
    
     pub fn view_id(&self) -> String {
        self.view_id.clone()
    }

    pub async fn get_all_filters(&self) -> Vec<FilterPB> {
        self.editor.get_all_filters(&self.view_id).await.items
    }

    pub async fn run_scripts(&mut self, scripts: Vec<FilterScript>) {
        for script in scripts {
            self.run_script(script).await;
        }
    }

    pub async fn run_script(&mut self, script: FilterScript) {
        match script {
            FilterScript::UpdateTextCell { row_id, text, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                self.update_text_cell(row_id, &text).await.unwrap();
            }
            FilterScript::UpdateChecklistCell { row_id, f } => {
                self.set_checklist_cell( row_id, f).await.unwrap();
            }
            FilterScript::UpdateSingleSelectCell { row_id, option_id, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                self.update_single_select_cell(row_id, &option_id).await.unwrap();
            }
            FilterScript::InsertFilter { payload } => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.insert_filter(payload).await;
            }
            FilterScript::CreateTextFilter { condition, content, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let field = self.get_first_field(FieldType::RichText);
                let text_filter= TextFilterPB {
                    condition,
                    content
                };
                let payload =
                    UpdateFilterPayloadPB::new(
                        & self.view_id(),
                        &field, text_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::UpdateTextFilter { filter, condition, content, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let params = UpdateFilterParams {
                    view_id: self.view_id(),
                    field_id: filter.field_id,
                    filter_id: Some(filter.id),
                    field_type: filter.field_type.into(),
                    condition: condition as i64,
                    content
                };
                self.editor.create_or_update_filter(params).await.unwrap();
            }
            FilterScript::CreateNumberFilter {condition, content, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let field = self.get_first_field(FieldType::Number);
                let number_filter = NumberFilterPB {
                    condition,
                    content
                };
                let payload =
                    UpdateFilterPayloadPB::new(
                        &self.view_id(),
                        &field, number_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateCheckboxFilter {condition, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let field = self.get_first_field(FieldType::Checkbox);
                let checkbox_filter = CheckboxFilterPB {
                    condition
                };
                let payload =
                    UpdateFilterPayloadPB::new(& self.view_id(), &field, checkbox_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateDateFilter { condition, start, end, timestamp, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let field = self.get_first_field(FieldType::DateTime);
                let date_filter = DateFilterPB {
                    condition,
                    start,
                    end,
                    timestamp
                };

                let payload =
                    UpdateFilterPayloadPB::new(&self.view_id(), &field, date_filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateMultiSelectFilter { condition, option_ids} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                let field = self.get_first_field(FieldType::MultiSelect);
                let filter = SelectOptionFilterPB { condition, option_ids };
                let payload =
                    UpdateFilterPayloadPB::new(&self.view_id(), &field, filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateSingleSelectFilter { condition, option_ids, changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let field = self.get_first_field(FieldType::SingleSelect);
                let filter = SelectOptionFilterPB { condition, option_ids };
                let payload =
                    UpdateFilterPayloadPB::new(& self.view_id(), &field, filter);
                self.insert_filter(payload).await;
            }
            FilterScript::CreateChecklistFilter { condition,changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let field = self.get_first_field(FieldType::Checklist);
                // let type_option = self.get_checklist_type_option(&field_rev.id);
                let filter = ChecklistFilterPB { condition };
                let payload =
                    UpdateFilterPayloadPB::new(& self.view_id(), &field, filter);
                self.insert_filter(payload).await;
            }
            FilterScript::AssertFilterCount { count } => {
                let filters = self.editor.get_all_filters(&self.view_id).await.items;
                assert_eq!(count as usize, filters.len());
            }
            FilterScript::AssertFilterContent { filter_id, condition, content} => {
                let filter = self.editor.get_filter(&self.view_id, &filter_id).await.unwrap();
                assert_eq!(&filter.content, &content);
                assert_eq!(filter.condition, condition);

            }
            FilterScript::DeleteFilter {  filter_id, filter_type ,changed} => {
                self.recv = Some(self.editor.subscribe_view_changed(&self.view_id()).await.unwrap());
                self.assert_future_changed(changed).await;
                let params = DeleteFilterParams { filter_id, view_id: self.view_id(),filter_type };
                let _ = self.editor.delete_filter(params).await.unwrap();
            }
            FilterScript::AssertGridSetting { expected_setting } => {
                let setting = self.editor.get_database_view_setting(&self.view_id).await.unwrap();
                assert_eq!(expected_setting, setting);
            }
            FilterScript::AssertNumberOfVisibleRows { expected } => {
                let grid = self.editor.get_database_data(&self.view_id).await.unwrap();
                assert_eq!(grid.rows.len(), expected);
            }
            FilterScript::Wait { millisecond } => {
                tokio::time::sleep(Duration::from_millis(millisecond)).await;
            }
        }
    }

    async fn assert_future_changed(&mut self, change: Option<FilterRowChanged>) {
        if change.is_none() {return;}
        let change = change.unwrap();
        let mut receiver = self.recv.take().unwrap();
        tokio::spawn(async move {
            match tokio::time::timeout(Duration::from_secs(2), receiver.recv()).await {
                Ok(changed) =>  {
                    match changed.unwrap() { DatabaseViewChanged::FilterNotification(notification) => {
                        assert_eq!(notification.visible_rows.len(), change.showing_num_of_rows, "visible rows not match");
                        assert_eq!(notification.invisible_rows.len(), change.hiding_num_of_rows, "invisible rows not match");
                    }
                        _ => {}
                    }
                },
                Err(e) => {
                    panic!("Process filter task timeout: {:?}", e);
                }
            }
        });


    }

    async fn insert_filter(&self, payload: UpdateFilterPayloadPB) {
        let params: UpdateFilterParams = payload.try_into().unwrap();
        let _ = self.editor.create_or_update_filter(params).await.unwrap();
    }

}


impl std::ops::Deref for DatabaseFilterTest {
    type Target = DatabaseEditorTest;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for DatabaseFilterTest {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}
