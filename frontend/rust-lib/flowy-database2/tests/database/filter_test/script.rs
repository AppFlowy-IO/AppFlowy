#![allow(dead_code)]

use std::time::Duration;

use collab_database::rows::RowId;
use flowy_database2::services::filter::{FilterChangeset, FilterInner};
use lib_infra::box_any::BoxAny;
use tokio::sync::broadcast::Receiver;

use flowy_database2::entities::{
  DatabaseViewSettingPB, FieldType, FilterPB, FilterType, TextFilterConditionPB, TextFilterPB,
};
use flowy_database2::services::database_view::DatabaseViewChanged;
use lib_dispatch::prelude::af_spawn;

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
  UpdateChecklistCell {
    row_id: RowId,
    selected_option_ids: Vec<String>,
  },
  UpdateSingleSelectCell {
    row_id: RowId,
    option_id: String,
    changed: Option<FilterRowChanged>,
  },
  CreateDataFilter {
    parent_filter_id: Option<String>,
    field_type: FieldType,
    data: BoxAny,
    changed: Option<FilterRowChanged>,
  },
  UpdateTextFilter {
    filter: FilterPB,
    condition: TextFilterConditionPB,
    content: String,
    changed: Option<FilterRowChanged>,
  },
  CreateAndFilter {
    parent_filter_id: Option<String>,
    changed: Option<FilterRowChanged>,
  },
  CreateOrFilter {
    parent_filter_id: Option<String>,
    changed: Option<FilterRowChanged>,
  },
  DeleteFilter {
    filter_id: String,
    field_id: String,
    changed: Option<FilterRowChanged>,
  },
  // CreateSimpleAdvancedFilter,
  // CreateComplexAdvancedFilter,
  AssertFilterCount {
    count: usize,
  },
  AssertNumberOfVisibleRows {
    expected: usize,
  },
  AssertFilters {
    /// 1. assert that the filter type is correct
    /// 2. if the filter is data, assert that the field_type, condition and content are correct
    /// (no field_id)
    /// 3. if the filter is and/or, assert that each child is correct as well.
    expected: Vec<FilterPB>,
  },
  // AssertSimpleAdvancedFilter,
  // AssertComplexAdvancedFilterResult,
  #[allow(dead_code)]
  AssertGridSetting {
    expected_setting: DatabaseViewSettingPB,
  },
  Wait {
    millisecond: u64,
  },
}

pub struct DatabaseFilterTest {
  inner: DatabaseEditorTest,
  recv: Option<Receiver<DatabaseViewChanged>>,
}

impl DatabaseFilterTest {
  pub async fn new() -> Self {
    let editor_test = DatabaseEditorTest::new_grid().await;
    Self {
      inner: editor_test,
      recv: None,
    }
  }

  pub async fn get_all_filters(&self) -> Vec<FilterPB> {
    self.editor.get_all_filters(&self.view_id).await.items
  }

  pub async fn get_filter(
    &self,
    filter_type: FilterType,
    field_type: Option<FieldType>,
  ) -> Option<FilterPB> {
    let filters = self.inner.editor.get_all_filters(&self.view_id).await;

    for filter in filters.items.iter() {
      let result = Self::find_filter(filter, filter_type, field_type);
      if result.is_some() {
        return result;
      }
    }

    None
  }

  fn find_filter(
    filter: &FilterPB,
    filter_type: FilterType,
    field_type: Option<FieldType>,
  ) -> Option<FilterPB> {
    match &filter.filter_type {
      FilterType::And | FilterType::Or if filter.filter_type == filter_type => Some(filter.clone()),
      FilterType::And | FilterType::Or => {
        for child_filter in filter.children.iter() {
          if let Some(result) = Self::find_filter(child_filter, filter_type, field_type) {
            return Some(result);
          }
        }
        None
      },
      FilterType::Data
        if filter.filter_type == filter_type
          && field_type.map_or(false, |field_type| {
            field_type == filter.data.clone().unwrap().field_type
          }) =>
      {
        Some(filter.clone())
      },
      _ => None,
    }
  }

  pub async fn run_scripts(&mut self, scripts: Vec<FilterScript>) {
    for script in scripts {
      self.run_script(script).await;
    }
  }

  pub async fn run_script(&mut self, script: FilterScript) {
    match script {
      FilterScript::UpdateTextCell {
        row_id,
        text,
        changed,
      } => {
        self.subscribe_view_changed().await;
        self.assert_future_changed(changed).await;
        self.update_text_cell(row_id, &text).await.unwrap();
      },
      FilterScript::UpdateChecklistCell {
        row_id,
        selected_option_ids,
      } => {
        self
          .set_checklist_cell(row_id, selected_option_ids)
          .await
          .unwrap();
      },
      FilterScript::UpdateSingleSelectCell {
        row_id,
        option_id,
        changed,
      } => {
        self.subscribe_view_changed().await;
        self.assert_future_changed(changed).await;
        self
          .update_single_select_cell(row_id, &option_id)
          .await
          .unwrap();
      },
      FilterScript::CreateDataFilter {
        parent_filter_id,
        field_type,
        data,
        changed,
      } => {
        self.subscribe_view_changed().await;
        self.assert_future_changed(changed).await;
        let field = self.get_first_field(field_type).await;
        let params = FilterChangeset::Insert {
          parent_filter_id,
          data: FilterInner::Data {
            field_id: field.id,
            field_type,
            condition_and_content: data,
          },
        };
        self
          .editor
          .modify_view_filters(&self.view_id, params)
          .await
          .unwrap();
      },
      FilterScript::UpdateTextFilter {
        filter,
        condition,
        content,
        changed,
      } => {
        self.subscribe_view_changed().await;

        self.assert_future_changed(changed).await;
        let current_filter = filter.data.unwrap();
        let params = FilterChangeset::UpdateData {
          filter_id: filter.id,
          data: FilterInner::Data {
            field_id: current_filter.field_id,
            field_type: current_filter.field_type,
            condition_and_content: BoxAny::new(TextFilterPB { condition, content }),
          },
        };
        self
          .editor
          .modify_view_filters(&self.view_id, params)
          .await
          .unwrap();
      },
      FilterScript::CreateAndFilter {
        parent_filter_id,
        changed,
      } => {
        self.subscribe_view_changed().await;
        self.assert_future_changed(changed).await;
        let params = FilterChangeset::Insert {
          parent_filter_id,
          data: FilterInner::And { children: vec![] },
        };
        self
          .editor
          .modify_view_filters(&self.view_id, params)
          .await
          .unwrap();
      },
      FilterScript::CreateOrFilter {
        parent_filter_id,
        changed,
      } => {
        self.subscribe_view_changed().await;
        self.assert_future_changed(changed).await;
        let params = FilterChangeset::Insert {
          parent_filter_id,
          data: FilterInner::Or { children: vec![] },
        };
        self
          .editor
          .modify_view_filters(&self.view_id, params)
          .await
          .unwrap();
      },
      FilterScript::AssertFilterCount { count } => {
        let filters = self.editor.get_all_filters(&self.view_id).await.items;
        assert_eq!(count, filters.len());
      },
      FilterScript::DeleteFilter {
        filter_id,
        field_id,
        changed,
      } => {
        self.subscribe_view_changed().await;
        self.assert_future_changed(changed).await;
        let params = FilterChangeset::Delete {
          filter_id,
          field_id,
        };
        self
          .editor
          .modify_view_filters(&self.view_id, params)
          .await
          .unwrap();
      },
      FilterScript::AssertGridSetting { expected_setting } => {
        let setting = self
          .editor
          .get_database_view_setting(&self.view_id)
          .await
          .unwrap();
        assert_eq!(expected_setting, setting);
      },
      FilterScript::AssertFilters { expected } => {
        let actual = self.get_all_filters().await;
        for (actual_filter, expected_filter) in actual.iter().zip(expected.iter()) {
          Self::assert_filter(actual_filter, expected_filter);
        }
      },
      FilterScript::AssertNumberOfVisibleRows { expected } => {
        let grid = self.editor.open_database_view(&self.view_id).await.unwrap();
        assert_eq!(grid.rows.len(), expected);
      },
      FilterScript::Wait { millisecond } => {
        tokio::time::sleep(Duration::from_millis(millisecond)).await;
      },
    }
  }

  async fn subscribe_view_changed(&mut self) {
    self.recv = Some(
      self
        .editor
        .subscribe_view_changed(&self.view_id)
        .await
        .unwrap(),
    );
  }

  async fn assert_future_changed(&mut self, change: Option<FilterRowChanged>) {
    if change.is_none() {
      return;
    }
    let change = change.unwrap();
    let mut receiver = self.recv.take().unwrap();
    af_spawn(async move {
      match tokio::time::timeout(Duration::from_secs(2), receiver.recv()).await {
        Ok(changed) => {
          if let DatabaseViewChanged::FilterNotification(notification) = changed.unwrap() {
            assert_eq!(
              notification.visible_rows.len(),
              change.showing_num_of_rows,
              "visible rows not match"
            );
            assert_eq!(
              notification.invisible_rows.len(),
              change.hiding_num_of_rows,
              "invisible rows not match"
            );
          }
        },
        Err(e) => {
          panic!("Process filter task timeout: {:?}", e);
        },
      }
    });
  }

  fn assert_filter(actual: &FilterPB, expected: &FilterPB) {
    assert_eq!(actual.filter_type, expected.filter_type);
    assert_eq!(actual.children.is_empty(), expected.children.is_empty());
    assert_eq!(actual.data.is_some(), expected.data.is_some());

    match actual.filter_type {
      FilterType::Data => {
        let actual_data = actual.data.clone().unwrap();
        let expected_data = expected.data.clone().unwrap();
        assert_eq!(actual_data.field_type, expected_data.field_type);
        assert_eq!(actual_data.data, expected_data.data);
      },
      FilterType::And | FilterType::Or => {
        for (actual_child, expected_child) in actual.children.iter().zip(expected.children.iter()) {
          Self::assert_filter(actual_child, expected_child);
        }
      },
    }
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
