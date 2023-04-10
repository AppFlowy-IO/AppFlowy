use crate::entities::{
  CalendarLayoutSettingsPB, DatabaseLayoutPB, DatabasePB, DatabaseViewSettingPB, FieldIdPB,
  FilterPB, GroupSettingPB, LayoutSettingPB, RowPB, SortPB,
};
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::Sort;
use collab_database::database::Database as InnerDatabase;
use collab_database::views::DatabaseView;
use std::sync::Arc;

pub(crate) fn get_database_data(database: &Arc<InnerDatabase>) -> DatabasePB {
  let database_id = database.get_database_id();
  let fields = database
    .fields
    .get_all_field_orders()
    .into_iter()
    .map(FieldIdPB::from)
    .collect();
  let rows = database
    .rows
    .get_all_row_orders()
    .into_iter()
    .map(RowPB::from)
    .collect();
  DatabasePB {
    id: database_id,
    fields,
    rows,
  }
}

pub(crate) fn database_view_setting_pb_from_view(view: DatabaseView) -> DatabaseViewSettingPB {
  let layout_setting = if let Some(layout_setting) = view.layout_settings.get(&view.layout) {
    let calendar_setting =
      CalendarLayoutSettingsPB::from(CalendarLayoutSetting::from(layout_setting.clone()));
    LayoutSettingPB {
      calendar: calendar_setting,
    }
  } else {
    LayoutSettingPB::default()
  };

  let current_layout: DatabaseLayoutPB = view.layout.into();
  let filters = view
    .filters
    .into_iter()
    .flat_map(|value| match Filter::try_from(value) {
      Ok(filter) => Some(FilterPB::from(&filter)),
      Err(_) => None,
    })
    .collect::<Vec<FilterPB>>();
  let group_settings = view
    .group_settings
    .into_iter()
    .flat_map(|value| match GroupSetting::try_from(value) {
      Ok(setting) => Some(GroupSettingPB::from(&setting)),
      Err(_) => None,
    })
    .collect::<Vec<GroupSettingPB>>();

  let sorts = view
    .sorts
    .into_iter()
    .flat_map(|value| match Sort::try_from(value) {
      Ok(sort) => Some(SortPB::from(&sort)),
      Err(_) => None,
    })
    .collect::<Vec<SortPB>>();

  DatabaseViewSettingPB {
    current_layout,
    filters: filters.into(),
    group_settings: group_settings.into(),
    sorts: sorts.into(),
    layout_setting,
  }
}
