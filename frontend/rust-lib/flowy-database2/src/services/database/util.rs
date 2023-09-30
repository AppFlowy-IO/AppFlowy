use collab_database::views::DatabaseView;

use crate::entities::{
  CalendarLayoutSettingPB, DatabaseLayoutPB, DatabaseLayoutSettingPB, DatabaseViewSettingPB,
  FieldSettingsPB, FilterPB, GroupSettingPB, SortPB,
};
use crate::services::field_settings::FieldSettings;
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::Sort;

pub(crate) fn database_view_setting_pb_from_view(view: DatabaseView) -> DatabaseViewSettingPB {
  let layout_type: DatabaseLayoutPB = view.layout.into();
  let layout_setting = if let Some(layout_setting) = view.layout_settings.get(&view.layout) {
    let calendar_setting =
      CalendarLayoutSettingPB::from(CalendarLayoutSetting::from(layout_setting.clone()));
    DatabaseLayoutSettingPB {
      layout_type: layout_type.clone(),
      calendar: Some(calendar_setting),
    }
  } else {
    DatabaseLayoutSettingPB::default()
  };

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

  let field_settings = view
    .field_settings
    .into_inner()
    .into_iter()
    .flat_map(|(field_id, field_settings)| FieldSettings::try_from_anymap(field_id, field_settings))
    .map(FieldSettingsPB::from)
    .collect::<Vec<FieldSettingsPB>>();

  DatabaseViewSettingPB {
    layout_type,
    filters: filters.into(),
    group_settings: group_settings.into(),
    sorts: sorts.into(),
    field_settings: field_settings.into(),
    layout_setting,
  }
}
