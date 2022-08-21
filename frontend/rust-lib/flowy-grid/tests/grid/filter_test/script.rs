#![cfg_attr(rustfmt, rustfmt::skip)]
#![allow(clippy::all)]
#![allow(dead_code)]
#![allow(unused_imports)]

use flowy_grid::entities::{CreateFilterParams, CreateGridFilterPayloadPB, DeleteFilterParams, GridLayout, GridSettingChangesetParams, GridSettingPB};
use flowy_grid::services::setting::GridSettingChangesetBuilder;
use flowy_grid_data_model::revision::{FieldRevision, FieldTypeRevision};
use crate::grid::grid_editor::GridEditorTest;

pub enum FilterScript {
    InsertGridTableFilter {
        payload: CreateGridFilterPayloadPB,
    },
    AssertTableFilterCount {
        count: i32,
    },
    DeleteGridTableFilter {
        filter_id: String,
        field_rev: FieldRevision,
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
           
            FilterScript::InsertGridTableFilter { payload } => {
                let params: CreateFilterParams = payload.try_into().unwrap();
                let _ = self.editor.update_filter(params).await.unwrap();
            }
            FilterScript::AssertTableFilterCount { count } => {
                let filters = self.editor.get_grid_filter().await.unwrap();
                assert_eq!(count as usize, filters.len());
            }
            FilterScript::DeleteGridTableFilter { filter_id, field_rev} => {
                let params = DeleteFilterParams { field_id: field_rev.id, filter_id, field_type_rev: field_rev.ty };
                let _ = self.editor.delete_filter(params).await.unwrap();
            }
            FilterScript::AssertGridSetting { expected_setting } => {
                let setting = self.editor.get_grid_setting().await.unwrap();
                assert_eq!(expected_setting, setting);
            }
        }
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
