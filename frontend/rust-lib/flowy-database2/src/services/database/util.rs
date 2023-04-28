use crate::entities::{
  CalendarLayoutSettingPB, DatabaseLayoutPB, DatabaseViewSettingPB, FilterPB, GroupSettingPB,
  LayoutSettingPB, SortPB,
};
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::Sort;
use collab_database::views::DatabaseView;

pub(crate) fn database_view_setting_pb_from_view(view: DatabaseView) -> DatabaseViewSettingPB {
  let layout_setting = if let Some(layout_setting) = view.layout_settings.get(&view.layout) {
    let calendar_setting =
      CalendarLayoutSettingPB::from(CalendarLayoutSetting::from(layout_setting.clone()));
    LayoutSettingPB {
      calendar: Some(calendar_setting),
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
