use collab::preclude::encoding::serde::from_any;
use collab::preclude::Any;
use collab_database::views::{LayoutSetting, LayoutSettingBuilder};
use serde::{Deserialize, Serialize};
use serde_repr::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarLayoutSetting {
  #[serde(default)]
  pub layout_ty: CalendarLayout,
  #[serde(default)]
  pub first_day_of_week: i32,
  #[serde(default)]
  pub show_weekends: bool,
  #[serde(default)]
  pub show_week_numbers: bool,
  #[serde(default)]
  pub field_id: String,
}

impl From<LayoutSetting> for CalendarLayoutSetting {
  fn from(setting: LayoutSetting) -> Self {
    from_any(&Any::from(setting)).unwrap()
  }
}

impl From<CalendarLayoutSetting> for LayoutSetting {
  fn from(setting: CalendarLayoutSetting) -> Self {
    LayoutSettingBuilder::from([
      ("layout_ty".into(), Any::BigInt(setting.layout_ty.value())),
      (
        "first_day_of_week".into(),
        Any::BigInt(setting.first_day_of_week as i64),
      ),
      (
        "show_week_numbers".into(),
        Any::Bool(setting.show_week_numbers),
      ),
      ("show_weekends".into(), Any::Bool(setting.show_weekends)),
      ("field_id".into(), setting.field_id.into()),
    ])
  }
}

impl CalendarLayoutSetting {
  pub fn new(field_id: String) -> Self {
    CalendarLayoutSetting {
      layout_ty: CalendarLayout::default(),
      first_day_of_week: DEFAULT_FIRST_DAY_OF_WEEK,
      show_weekends: DEFAULT_SHOW_WEEKENDS,
      show_week_numbers: DEFAULT_SHOW_WEEK_NUMBERS,
      field_id,
    }
  }
}

#[derive(Debug, Copy, Clone, Eq, PartialEq, Default, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum CalendarLayout {
  #[default]
  Month = 0,
  Week = 1,
  Day = 2,
}

impl From<i64> for CalendarLayout {
  fn from(value: i64) -> Self {
    match value {
      0 => CalendarLayout::Month,
      1 => CalendarLayout::Week,
      2 => CalendarLayout::Day,
      _ => CalendarLayout::Month,
    }
  }
}

impl CalendarLayout {
  pub fn value(&self) -> i64 {
    *self as i64
  }
}

pub const DEFAULT_FIRST_DAY_OF_WEEK: i32 = 0;
pub const DEFAULT_SHOW_WEEKENDS: bool = true;
pub const DEFAULT_SHOW_WEEK_NUMBERS: bool = true;

#[derive(Debug, Clone, Default, Deserialize)]
pub struct BoardLayoutSetting {
  #[serde(default)]
  pub hide_ungrouped_column: bool,
  #[serde(default)]
  pub collapse_hidden_groups: bool,
  #[serde(default)]
  pub fetch_url_meta_data: bool,
}

impl BoardLayoutSetting {
  pub fn new() -> Self {
    Self::default()
  }
}

impl From<LayoutSetting> for BoardLayoutSetting {
  fn from(setting: LayoutSetting) -> Self {
    from_any(&Any::from(setting)).unwrap()
  }
}

impl From<BoardLayoutSetting> for LayoutSetting {
  fn from(setting: BoardLayoutSetting) -> Self {
    LayoutSettingBuilder::from([
      (
        "hide_ungrouped_column".into(),
        setting.hide_ungrouped_column.into(),
      ),
      (
        "collapse_hidden_groups".into(),
        setting.collapse_hidden_groups.into(),
      ),
      (
        "fetch_url_meta_data".into(),
        setting.fetch_url_meta_data.into(),
      ),
    ])
  }
}
