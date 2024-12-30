use crate::entities::{
  DatabaseLayoutPB, DatabaseLayoutSettingPB, DatabaseViewSettingPB, FieldSettingsPB, FilterPB,
  GroupSettingPB, SortPB,
};
use crate::services::field_settings::FieldSettings;
use crate::services::filter::Filter;
use crate::services::group::GroupSetting;
use crate::services::sort::Sort;
use collab_database::entity::DatabaseView;
use collab_database::views::DatabaseLayout;
use tracing::error;

pub(crate) fn database_view_setting_pb_from_view(view: DatabaseView) -> DatabaseViewSettingPB {
  let layout_type: DatabaseLayoutPB = view.layout.into();
  let layout_setting = if let Some(layout_setting) = view.layout_settings.get(&view.layout) {
    match view.layout {
      DatabaseLayout::Board => {
        let board_setting = layout_setting.clone().into();
        DatabaseLayoutSettingPB::from_board(board_setting)
      },
      DatabaseLayout::Calendar => {
        let calendar_setting = layout_setting.clone().into();
        DatabaseLayoutSettingPB::from_calendar(calendar_setting)
      },
      _ => DatabaseLayoutSettingPB::default(),
    }
  } else {
    DatabaseLayoutSettingPB::default()
  };

  let filters = view
    .filters
    .into_iter()
    .flat_map(|value| match Filter::try_from(value) {
      Ok(filter) => Some(FilterPB::from(&filter)),
      Err(err) => {
        error!("Error converting filter: {:?}", err);
        None
      },
    })
    .collect::<Vec<FilterPB>>();

  let group_settings = view
    .group_settings
    .into_iter()
    .flat_map(|value| match GroupSetting::try_from(value) {
      Ok(setting) => Some(GroupSettingPB::from(&setting)),
      Err(err) => {
        error!("Error converting group setting: {:?}", err);
        None
      },
    })
    .collect::<Vec<GroupSettingPB>>();

  let sorts = view
    .sorts
    .into_iter()
    .flat_map(|value| match Sort::try_from(value) {
      Ok(sort) => Some(SortPB::from(&sort)),
      Err(err) => {
        error!("Error converting sort: {:?}", err);
        None
      },
    })
    .collect::<Vec<SortPB>>();

  let field_settings = view
    .field_settings
    .into_inner()
    .into_iter()
    .map(|(field_id, field_settings)| {
      FieldSettings::from_any_map(&field_id, view.layout, &field_settings)
    })
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
