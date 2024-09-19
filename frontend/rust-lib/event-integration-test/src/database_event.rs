use std::collections::HashMap;
use std::convert::TryFrom;

use bytes::Bytes;
use collab_database::database::timestamp;
use collab_database::entity::SelectOption;
use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use flowy_database2::entities::*;
use flowy_database2::event_map::DatabaseEvent;
use flowy_database2::services::cell::CellBuilder;
use flowy_database2::services::field::{MultiSelectTypeOption, SingleSelectTypeOption};
use flowy_database2::services::share::csv::CSVFormat;
use flowy_folder::entities::*;
use flowy_folder::event_map::FolderEvent;
use flowy_user::errors::FlowyError;

use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;

impl EventIntegrationTest {
  pub async fn get_database_export_data(&self, database_view_id: &str) -> String {
    self
      .appflowy_core
      .database_manager
      .get_database_editor_with_view_id(database_view_id)
      .await
      .unwrap()
      .export_csv(CSVFormat::Original)
      .await
      .unwrap()
  }

  /// The initial data can refer to the [FolderOperationHandler::create_view_with_view_data] method.
  pub async fn create_grid(&self, parent_id: &str, name: String, initial_data: Vec<u8>) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Grid,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
      section: None,
      view_id: None,
      extra: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>()
  }

  pub async fn open_database(&self, view_id: &str) {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetDatabase)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await;
  }

  pub async fn create_board(&self, parent_id: &str, name: String, initial_data: Vec<u8>) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Board,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
      section: None,
      view_id: None,
      extra: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>()
  }

  pub async fn create_calendar(
    &self,
    parent_id: &str,
    name: String,
    initial_data: Vec<u8>,
  ) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Calendar,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
      section: None,
      view_id: None,
      extra: None,
    };
    EventBuilder::new(self.clone())
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>()
  }

  pub async fn get_database(&self, view_id: &str) -> DatabasePB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetDatabase)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<DatabasePB>()
  }

  pub async fn get_all_database_fields(&self, view_id: &str) -> RepeatedFieldPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetFields)
      .payload(GetFieldPayloadPB {
        view_id: view_id.to_string(),
        field_ids: None,
      })
      .async_send()
      .await
      .parse::<RepeatedFieldPB>()
  }

  pub async fn create_field(&self, view_id: &str, field_type: FieldType) -> FieldPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::CreateField)
      .payload(CreateFieldPayloadPB {
        view_id: view_id.to_string(),
        field_type,
        ..Default::default()
      })
      .async_send()
      .await
      .parse::<FieldPB>()
  }

  pub async fn update_field(&self, changeset: FieldChangesetPB) {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateField)
      .payload(changeset)
      .async_send()
      .await;
  }

  pub async fn delete_field(&self, view_id: &str, field_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DeleteField)
      .payload(DeleteFieldPayloadPB {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_field_type(
    &self,
    view_id: &str,
    field_id: &str,
    field_type: FieldType,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateFieldType)
      .payload(UpdateFieldTypePayloadPB {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
        field_type,
        field_name: None,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn duplicate_field(&self, view_id: &str, field_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DuplicateField)
      .payload(DuplicateFieldPayloadPB {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn get_primary_field(&self, database_view_id: &str) -> FieldPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetPrimaryField)
      .payload(DatabaseViewIdPB {
        value: database_view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<FieldPB>()
  }
  pub async fn summary_row(&self, data: SummaryRowPB) {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::SummarizeRow)
      .payload(data)
      .async_send()
      .await;
  }

  pub async fn translate_row(&self, data: TranslateRowPB) {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::TranslateRow)
      .payload(data)
      .async_send()
      .await;
  }

  pub async fn create_row(
    &self,
    view_id: &str,
    row_position: OrderObjectPositionPB,
    data: Option<HashMap<String, String>>,
  ) -> RowMetaPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::CreateRow)
      .payload(CreateRowPayloadPB {
        view_id: view_id.to_string(),
        row_position,
        group_id: None,
        data: data.unwrap_or_default(),
      })
      .async_send()
      .await
      .parse::<RowMetaPB>()
  }

  pub async fn delete_row(&self, view_id: &str, row_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DeleteRows)
      .payload(RepeatedRowIdPB {
        view_id: view_id.to_string(),
        row_ids: vec![row_id.to_string()],
      })
      .async_send()
      .await
      .error()
  }

  pub async fn get_row(&self, view_id: &str, row_id: &str) -> OptionalRowPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetRow)
      .payload(DatabaseViewRowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .parse::<OptionalRowPB>()
  }

  pub async fn get_row_meta(&self, view_id: &str, row_id: &str) -> RowMetaPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetRowMeta)
      .payload(DatabaseViewRowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .parse::<RowMetaPB>()
  }

  pub async fn update_row_meta(&self, changeset: UpdateRowMetaChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateRowMeta)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn duplicate_row(&self, view_id: &str, row_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DuplicateRow)
      .payload(DatabaseViewRowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn move_row(&self, view_id: &str, row_id: &str, to_row_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::MoveRow)
      .payload(MoveRowPayloadPB {
        view_id: view_id.to_string(),
        from_row_id: row_id.to_string(),
        to_row_id: to_row_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_cell(&self, changeset: CellChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn update_date_cell(&self, changeset: DateCellChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateDateCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn get_cell(&self, view_id: &str, row_id: &str, field_id: &str) -> CellPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetCell)
      .payload(CellIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        field_id: field_id.to_string(),
      })
      .async_send()
      .await
      .parse::<CellPB>()
  }

  pub async fn get_text_cell(&self, view_id: &str, row_id: &str, field_id: &str) -> String {
    let cell = self.get_cell(view_id, row_id, field_id).await;
    String::from_utf8(cell.data).unwrap()
  }

  pub async fn get_date_cell(&self, view_id: &str, row_id: &str, field_id: &str) -> DateCellDataPB {
    let cell = self.get_cell(view_id, row_id, field_id).await;
    DateCellDataPB::try_from(Bytes::from(cell.data)).unwrap()
  }

  pub async fn get_checklist_cell(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: &str,
  ) -> ChecklistCellDataPB {
    let cell = self.get_cell(view_id, row_id, field_id).await;
    ChecklistCellDataPB::try_from(Bytes::from(cell.data)).unwrap()
  }

  pub async fn get_relation_cell(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: &str,
  ) -> RelationCellDataPB {
    let cell = self.get_cell(view_id, row_id, field_id).await;
    RelationCellDataPB::try_from(Bytes::from(cell.data)).unwrap_or_default()
  }

  pub async fn update_checklist_cell(
    &self,
    changeset: ChecklistCellDataChangesetPB,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateChecklistCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn insert_option(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: &str,
    name: &str,
  ) -> Option<FlowyError> {
    let option = EventBuilder::new(self.clone())
      .event(DatabaseEvent::CreateSelectOption)
      .payload(CreateSelectOptionPayloadPB {
        field_id: field_id.to_string(),
        view_id: view_id.to_string(),
        option_name: name.to_string(),
      })
      .async_send()
      .await
      .parse::<SelectOptionPB>();

    EventBuilder::new(self.clone())
      .event(DatabaseEvent::InsertOrUpdateSelectOption)
      .payload(RepeatedSelectOptionPayload {
        view_id: view_id.to_string(),
        field_id: field_id.to_string(),
        row_id: row_id.to_string(),
        items: vec![option],
      })
      .async_send()
      .await
      .error()
  }

  pub async fn get_groups(&self, view_id: &str) -> Vec<GroupPB> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetGroups)
      .payload(DatabaseViewIdPB {
        value: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedGroupPB>()
      .items
  }

  pub async fn move_group(&self, view_id: &str, from_id: &str, to_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::MoveGroup)
      .payload(MoveGroupPayloadPB {
        view_id: view_id.to_string(),
        from_group_id: from_id.to_string(),
        to_group_id: to_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn set_group_by_field(
    &self,
    view_id: &str,
    field_id: &str,
    setting_content: Vec<u8>,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::SetGroupByField)
      .payload(GroupByFieldPayloadPB {
        field_id: field_id.to_string(),
        view_id: view_id.to_string(),
        setting_content,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_group(
    &self,
    view_id: &str,
    group_id: &str,
    name: Option<String>,
    visible: Option<bool>,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateGroup)
      .payload(UpdateGroupPB {
        view_id: view_id.to_string(),
        group_id: group_id.to_string(),
        name,
        visible,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn delete_group(&self, view_id: &str, group_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::DeleteGroup)
      .payload(DeleteGroupPayloadPB {
        view_id: view_id.to_string(),
        group_id: group_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_setting(&self, changeset: DatabaseSettingChangesetPB) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateDatabaseSetting)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn get_all_calendar_events(&self, view_id: &str) -> Vec<CalendarEventPB> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetAllCalendarEvents)
      .payload(CalendarEventRequestPB {
        view_id: view_id.to_string(),
      })
      .async_send()
      .await
      .parse::<RepeatedCalendarEventPB>()
      .items
  }

  pub async fn update_relation_cell(
    &self,
    changeset: RelationCellChangesetPB,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateRelationCell)
      .payload(changeset)
      .async_send()
      .await
      .error()
  }

  pub async fn get_related_row_data(
    &self,
    database_id: String,
    row_ids: Vec<String>,
  ) -> Vec<RelatedRowDataPB> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetRelatedRowDatas)
      .payload(GetRelatedRowDataPB {
        database_id,
        row_ids,
      })
      .async_send()
      .await
      .parse::<RepeatedRelatedRowDataPB>()
      .rows
  }
}

pub struct TestRowBuilder<'a> {
  database_id: &'a str,
  row_id: RowId,
  fields: &'a [Field],
  cell_build: CellBuilder<'a>,
}

impl<'a> TestRowBuilder<'a> {
  pub fn new(database_id: &'a str, row_id: RowId, fields: &'a [Field]) -> Self {
    let cell_build = CellBuilder::with_cells(Default::default(), fields);
    Self {
      database_id,
      row_id,
      fields,
      cell_build,
    }
  }

  pub fn insert_text_cell(&mut self, data: &str) -> String {
    let text_field = self.field_with_type(&FieldType::RichText);
    self
      .cell_build
      .insert_text_cell(&text_field.id, data.to_string());

    text_field.id.clone()
  }

  pub fn insert_number_cell(&mut self, data: &str) -> String {
    let number_field = self.field_with_type(&FieldType::Number);
    self
      .cell_build
      .insert_text_cell(&number_field.id, data.to_string());
    number_field.id.clone()
  }

  pub fn insert_date_cell(
    &mut self,
    date: i64,
    time: Option<String>,
    include_time: Option<bool>,
    field_type: &FieldType,
  ) -> String {
    let date_field = self.field_with_type(field_type);
    self
      .cell_build
      .insert_date_cell(&date_field.id, date, time, include_time);
    date_field.id.clone()
  }

  pub fn insert_checkbox_cell(&mut self, data: &str) -> String {
    let checkbox_field = self.field_with_type(&FieldType::Checkbox);
    self
      .cell_build
      .insert_text_cell(&checkbox_field.id, data.to_string());

    checkbox_field.id.clone()
  }

  pub fn insert_url_cell(&mut self, content: &str) -> String {
    let url_field = self.field_with_type(&FieldType::URL);
    self
      .cell_build
      .insert_url_cell(&url_field.id, content.to_string());
    url_field.id.clone()
  }

  pub fn insert_single_select_cell<F>(&mut self, f: F) -> String
  where
    F: Fn(Vec<SelectOption>) -> SelectOption,
  {
    let single_select_field = self.field_with_type(&FieldType::SingleSelect);
    let type_option = single_select_field
      .get_type_option::<SingleSelectTypeOption>(FieldType::SingleSelect)
      .unwrap();
    let option = f(type_option.options);
    self
      .cell_build
      .insert_select_option_cell(&single_select_field.id, vec![option.id]);

    single_select_field.id.clone()
  }

  pub fn insert_multi_select_cell<F>(&mut self, f: F) -> String
  where
    F: Fn(Vec<SelectOption>) -> Vec<SelectOption>,
  {
    let multi_select_field = self.field_with_type(&FieldType::MultiSelect);
    let type_option = multi_select_field
      .get_type_option::<MultiSelectTypeOption>(FieldType::MultiSelect)
      .unwrap();
    let options = f(type_option.options);
    let ops_ids = options
      .iter()
      .map(|option| option.id.clone())
      .collect::<Vec<_>>();
    self
      .cell_build
      .insert_select_option_cell(&multi_select_field.id, ops_ids);

    multi_select_field.id.clone()
  }

  pub fn insert_checklist_cell(&mut self, options: Vec<(String, bool)>) -> String {
    let checklist_field = self.field_with_type(&FieldType::Checklist);
    self
      .cell_build
      .insert_checklist_cell(&checklist_field.id, options);
    checklist_field.id.clone()
  }

  pub fn insert_time_cell(&mut self, time: i64) -> String {
    let time_field = self.field_with_type(&FieldType::Time);
    self.cell_build.insert_number_cell(&time_field.id, time);
    time_field.id.clone()
  }

  pub fn insert_media_cell(&mut self, media: String) -> String {
    let media_field = self.field_with_type(&FieldType::Media);
    self.cell_build.insert_text_cell(&media_field.id, media);
    media_field.id.clone()
  }

  pub fn field_with_type(&self, field_type: &FieldType) -> Field {
    self
      .fields
      .iter()
      .find(|field| {
        let t_field_type = FieldType::from(field.field_type);
        &t_field_type == field_type
      })
      .unwrap()
      .clone()
  }

  pub fn build(self) -> Row {
    let timestamp = timestamp();
    Row {
      id: self.row_id,
      database_id: self.database_id.to_string(),
      cells: self.cell_build.build(),
      height: 60,
      visibility: true,
      modified_at: timestamp,
      created_at: timestamp,
    }
  }
}
