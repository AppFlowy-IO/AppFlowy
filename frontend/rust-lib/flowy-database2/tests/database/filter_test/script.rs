#![allow(dead_code)]

use std::time::Duration;

use collab_database::rows::RowId;
use flowy_database2::services::filter::{FilterChangeset, FilterInner};
use lib_infra::box_any::BoxAny;
use tokio::sync::broadcast::Receiver;

use flowy_database2::entities::{
  CheckboxFilterConditionPB, CheckboxFilterPB, ChecklistFilterConditionPB, ChecklistFilterPB,
  DatabaseViewSettingPB, DateFilterConditionPB, DateFilterPB, FieldType, FilterPB,
  NumberFilterConditionPB, NumberFilterPB, SelectOptionConditionPB, SelectOptionFilterPB,
  TextFilterConditionPB, TextFilterPB,
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
  CreateDateFilter {
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
    count: usize,
  },
  DeleteFilter {
    filter_id: String,
    field_id: String,
    changed: Option<FilterRowChanged>,
  },
  AssertNumberOfVisibleRows {
    expected: usize,
  },
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
      FilterScript::UpdateTextCell {
        row_id,
        text,
        changed,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
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
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.assert_future_changed(changed).await;
        self
          .update_single_select_cell(row_id, &option_id)
          .await
          .unwrap();
      },
      FilterScript::CreateTextFilter {
        condition,
        content,
        changed,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.assert_future_changed(changed).await;
        let field = self.get_first_field(FieldType::RichText);
        let text_filter = BoxAny::new(TextFilterPB { condition, content });
        self
          .insert_filter(field.id, field.field_type.into(), text_filter)
          .await;
      },
      FilterScript::UpdateTextFilter {
        filter,
        condition,
        content,
        changed,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
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
      FilterScript::CreateNumberFilter {
        condition,
        content,
        changed,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.assert_future_changed(changed).await;
        let field = self.get_first_field(FieldType::Number);
        let number_filter = BoxAny::new(NumberFilterPB { condition, content });
        self
          .insert_filter(field.id, field.field_type.into(), number_filter)
          .await;
      },
      FilterScript::CreateCheckboxFilter { condition, changed } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.assert_future_changed(changed).await;
        let field = self.get_first_field(FieldType::Checkbox);
        let checkbox_filter = BoxAny::new(CheckboxFilterPB { condition });
        self
          .insert_filter(field.id, field.field_type.into(), checkbox_filter)
          .await;
      },
      FilterScript::CreateDateFilter {
        condition,
        start,
        end,
        timestamp,
        changed,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.assert_future_changed(changed).await;
        let field = self.get_first_field(FieldType::DateTime);
        let date_filter = BoxAny::new(DateFilterPB {
          condition,
          start,
          end,
          timestamp,
        });
        self
          .insert_filter(field.id, field.field_type.into(), date_filter)
          .await;
      },
      FilterScript::CreateMultiSelectFilter {
        condition,
        option_ids,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        let field = self.get_first_field(FieldType::MultiSelect);
        let select_option_filter = BoxAny::new(SelectOptionFilterPB {
          condition,
          option_ids,
        });
        self
          .insert_filter(field.id, field.field_type.into(), select_option_filter)
          .await;
      },
      FilterScript::CreateSingleSelectFilter {
        condition,
        option_ids,
        changed,
      } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.assert_future_changed(changed).await;
        let field = self.get_first_field(FieldType::SingleSelect);
        let select_option_filter = BoxAny::new(SelectOptionFilterPB {
          condition,
          option_ids,
        });
        self
          .insert_filter(field.id, field.field_type.into(), select_option_filter)
          .await;
      },
      FilterScript::CreateChecklistFilter { condition, changed } => {
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
        self.assert_future_changed(changed).await;
        let field = self.get_first_field(FieldType::Checklist);
        let checklist_filter = BoxAny::new(ChecklistFilterPB { condition });
        self
          .insert_filter(field.id, field.field_type.into(), checklist_filter)
          .await;
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
        self.recv = Some(
          self
            .editor
            .subscribe_view_changed(&self.view_id)
            .await
            .unwrap(),
        );
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
      FilterScript::AssertNumberOfVisibleRows { expected } => {
        let grid = self.editor.get_database_data(&self.view_id).await.unwrap();
        assert_eq!(grid.rows.len(), expected);
      },
      FilterScript::Wait { millisecond } => {
        tokio::time::sleep(Duration::from_millis(millisecond)).await;
      },
    }
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

  async fn insert_filter(&self, field_id: String, field_type: FieldType, payload: BoxAny) {
    let params = FilterChangeset::Insert {
      parent_filter_id: None,
      data: FilterInner::Data {
        field_id,
        field_type,
        condition_and_content: payload,
      },
    };
    self
      .editor
      .modify_view_filters(&self.view_id, params)
      .await
      .unwrap();
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
