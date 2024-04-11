use std::collections::HashMap;
use std::convert::TryFrom;

use bytes::Bytes;
use flowy_database2::entities::*;
use flowy_database2::event_map::DatabaseEvent;
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
      .get_database_with_view_id(database_view_id)
      .await
      .unwrap()
      .export_csv(CSVFormat::Original)
      .await
      .unwrap()
  }

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
      .event(DatabaseEvent::DeleteRow)
      .payload(RowIdPB {
        view_id: view_id.to_string(),
        row_id: row_id.to_string(),
        group_id: None,
      })
      .async_send()
      .await
      .error()
  }

  pub async fn get_row(&self, view_id: &str, row_id: &str) -> OptionalRowPB {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::GetRow)
      .payload(RowIdPB {
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
      .payload(RowIdPB {
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
      .payload(RowIdPB {
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

  pub async fn set_group_by_field(&self, view_id: &str, field_id: &str) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::SetGroupByField)
      .payload(GroupByFieldPayloadPB {
        field_id: field_id.to_string(),
        view_id: view_id.to_string(),
      })
      .async_send()
      .await
      .error()
  }

  pub async fn update_group(
    &self,
    view_id: &str,
    group_id: &str,
    field_id: &str,
    name: Option<String>,
    visible: Option<bool>,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.clone())
      .event(DatabaseEvent::UpdateGroup)
      .payload(UpdateGroupPB {
        view_id: view_id.to_string(),
        group_id: group_id.to_string(),
        field_id: field_id.to_string(),
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
      .payload(RepeatedRowIdPB {
        database_id,
        row_ids,
      })
      .async_send()
      .await
      .parse::<RepeatedRelatedRowDataPB>()
      .rows
  }
}
