use std::convert::TryInto;

use collab_database::views::DatabaseLayout;
use strum_macros::EnumIter;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use validator::Validate;

use crate::entities::parser::NotEmptyStr;
use crate::entities::{
  CalendarLayoutSettingPB, DeleteFilterPB, DeleteSortPayloadPB, InsertFilterPB,
  RepeatedFieldSettingsPB, RepeatedFilterPB, RepeatedGroupSettingPB, RepeatedSortPB,
  UpdateFilterDataPB, UpdateFilterTypePB, UpdateGroupPB, UpdateSortPayloadPB,
};
use crate::services::setting::{BoardLayoutSetting, CalendarLayoutSetting};

use super::{BoardLayoutSettingPB, ReorderSortPayloadPB};

/// [DatabaseViewSettingPB] defines the setting options for the grid. Such as the filter, group, and sort.
#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct DatabaseViewSettingPB {
  #[pb(index = 1)]
  pub layout_type: DatabaseLayoutPB,

  #[pb(index = 2)]
  pub layout_setting: DatabaseLayoutSettingPB,

  #[pb(index = 3)]
  pub filters: RepeatedFilterPB,

  #[pb(index = 4)]
  pub group_settings: RepeatedGroupSettingPB,

  #[pb(index = 5)]
  pub sorts: RepeatedSortPB,

  #[pb(index = 6)]
  pub field_settings: RepeatedFieldSettingsPB,
}

#[derive(Debug, Default, Clone, PartialEq, Eq, ProtoBuf_Enum, EnumIter)]
#[repr(u8)]
pub enum DatabaseLayoutPB {
  #[default]
  Grid = 0,
  Board = 1,
  Calendar = 2,
}

impl std::convert::From<DatabaseLayout> for DatabaseLayoutPB {
  fn from(rev: DatabaseLayout) -> Self {
    match rev {
      DatabaseLayout::Grid => DatabaseLayoutPB::Grid,
      DatabaseLayout::Board => DatabaseLayoutPB::Board,
      DatabaseLayout::Calendar => DatabaseLayoutPB::Calendar,
    }
  }
}

impl std::convert::From<DatabaseLayoutPB> for DatabaseLayout {
  fn from(layout: DatabaseLayoutPB) -> Self {
    match layout {
      DatabaseLayoutPB::Grid => DatabaseLayout::Grid,
      DatabaseLayoutPB::Board => DatabaseLayout::Board,
      DatabaseLayoutPB::Calendar => DatabaseLayout::Calendar,
    }
  }
}

#[derive(Default, Validate, ProtoBuf)]
pub struct DatabaseSettingChangesetPB {
  #[pb(index = 1)]
  #[validate(custom = "lib_infra::validator_fn::required_not_empty_str")]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub layout_type: Option<DatabaseLayoutPB>,

  #[pb(index = 3, one_of)]
  #[validate]
  pub insert_filter: Option<InsertFilterPB>,

  #[pb(index = 4, one_of)]
  #[validate]
  pub update_filter_type: Option<UpdateFilterTypePB>,

  #[pb(index = 5, one_of)]
  #[validate]
  pub update_filter_data: Option<UpdateFilterDataPB>,

  #[pb(index = 6, one_of)]
  #[validate]
  pub delete_filter: Option<DeleteFilterPB>,

  #[pb(index = 7, one_of)]
  #[validate]
  pub update_group: Option<UpdateGroupPB>,

  #[pb(index = 8, one_of)]
  #[validate]
  pub update_sort: Option<UpdateSortPayloadPB>,

  #[pb(index = 9, one_of)]
  #[validate]
  pub reorder_sort: Option<ReorderSortPayloadPB>,

  #[pb(index = 10, one_of)]
  #[validate]
  pub delete_sort: Option<DeleteSortPayloadPB>,
}

#[derive(Debug, Eq, PartialEq, Default, ProtoBuf, Clone)]
pub struct DatabaseLayoutSettingPB {
  #[pb(index = 1)]
  pub layout_type: DatabaseLayoutPB,

  #[pb(index = 2, one_of)]
  pub board: Option<BoardLayoutSettingPB>,

  #[pb(index = 3, one_of)]
  pub calendar: Option<CalendarLayoutSettingPB>,
}

impl DatabaseLayoutSettingPB {
  pub fn from_board(layout_setting: BoardLayoutSetting) -> Self {
    Self {
      layout_type: DatabaseLayoutPB::Board,
      board: Some(layout_setting.into()),
      calendar: None,
    }
  }

  pub fn from_calendar(layout_setting: CalendarLayoutSetting) -> Self {
    Self {
      layout_type: DatabaseLayoutPB::Calendar,
      calendar: Some(layout_setting.into()),
      board: None,
    }
  }
}

#[derive(Debug, Clone, Default)]
pub struct LayoutSettingParams {
  pub layout_type: DatabaseLayout,
  pub board: Option<BoardLayoutSetting>,
  pub calendar: Option<CalendarLayoutSetting>,
}

impl LayoutSettingParams {
  pub fn new(layout_type: DatabaseLayout) -> Self {
    Self {
      layout_type,
      ..Default::default()
    }
  }
}

impl From<LayoutSettingParams> for DatabaseLayoutSettingPB {
  fn from(data: LayoutSettingParams) -> Self {
    Self {
      layout_type: data.layout_type.into(),
      board: data.board.map(|board| board.into()),
      calendar: data.calendar.map(|calendar| calendar.into()),
    }
  }
}

#[derive(Debug, Eq, PartialEq, Default, ProtoBuf, Clone)]
pub struct LayoutSettingChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub layout_type: DatabaseLayoutPB,

  #[pb(index = 3, one_of)]
  pub board: Option<BoardLayoutSettingPB>,

  #[pb(index = 4, one_of)]
  pub calendar: Option<CalendarLayoutSettingPB>,
}

#[derive(Debug)]
pub struct LayoutSettingChangeset {
  pub view_id: String,
  pub layout_type: DatabaseLayout,
  pub board: Option<BoardLayoutSetting>,
  pub calendar: Option<CalendarLayoutSetting>,
}

impl LayoutSettingChangeset {
  pub fn is_valid(&self) -> bool {
    self.board.is_some() && self.layout_type == DatabaseLayout::Board
      || self.calendar.is_some() && self.layout_type == DatabaseLayout::Calendar
  }
}

impl TryInto<LayoutSettingChangeset> for LayoutSettingChangesetPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<LayoutSettingChangeset, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::ViewIdIsInvalid)?
      .0;

    Ok(LayoutSettingChangeset {
      view_id,
      layout_type: self.layout_type.into(),
      board: self.board.map(Into::into),
      calendar: self.calendar.map(Into::into),
    })
  }
}
