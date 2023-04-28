use collab::core::any_map::AnyMapExtension;
use collab_database::views::{LayoutSetting, LayoutSettingBuilder};
use serde::{Deserialize, Serialize};
use serde_repr::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarLayoutSetting {
  pub layout_ty: CalendarLayout,
  pub first_day_of_week: i32,
  pub show_weekends: bool,
  pub show_week_numbers: bool,
  pub field_id: String,
}

impl From<LayoutSetting> for CalendarLayoutSetting {
  fn from(setting: LayoutSetting) -> Self {
    let layout_ty = setting
      .get_i64_value("layout_ty")
      .map(CalendarLayout::from)
      .unwrap_or_default();
    let first_day_of_week = setting
      .get_i64_value("first_day_of_week")
      .unwrap_or(DEFAULT_FIRST_DAY_OF_WEEK as i64) as i32;
    let show_weekends = setting.get_bool_value("show_weekends").unwrap_or_default();
    let show_week_numbers = setting
      .get_bool_value("show_week_numbers")
      .unwrap_or_default();
    let field_id = setting.get_str_value("field_id").unwrap_or_default();
    Self {
      layout_ty,
      first_day_of_week,
      show_weekends,
      show_week_numbers,
      field_id,
    }
  }
}

impl From<CalendarLayoutSetting> for LayoutSetting {
  fn from(setting: CalendarLayoutSetting) -> Self {
    LayoutSettingBuilder::new()
      .insert_i64_value("layout_ty", setting.layout_ty.value())
      .insert_i64_value("first_day_of_week", setting.first_day_of_week as i64)
      .insert_bool_value("show_week_numbers", setting.show_week_numbers)
      .insert_bool_value("show_weekends", setting.show_weekends)
      .insert_str_value("field_id", setting.field_id)
      .build()
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
