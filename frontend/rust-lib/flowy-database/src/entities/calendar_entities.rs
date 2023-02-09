use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};
use std::convert::TryInto;

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, Default, ProtoBuf)]
pub struct CalendarSettingsPB {
  #[pb(index = 1)]
  pub layout_ty: CalendarLayout,

  #[pb(index = 2)]
  pub first_day_of_week: i32,

  #[pb(index = 3)]
  pub show_weekends: bool,

  #[pb(index = 4)]
  pub show_week_numbers: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarSettingsParams {
  layout_ty: CalendarLayout,
  first_day_of_week: i32,
  show_weekends: bool,
  show_week_numbers: bool,
}

const DEFAULT_FIRST_DAY_OF_WEEK: i32 = 0;
const DEFAULT_SHOW_WEEKENDS: bool = true;
const DEFAULT_SHOW_WEEK_NUMBERS: bool = true;

impl std::default::Default for CalendarSettingsParams {
  // The default settings will be used if there is no existing settings
  fn default() -> Self {
    CalendarSettingsParams {
      layout_ty: CalendarLayout::default(),
      first_day_of_week: DEFAULT_FIRST_DAY_OF_WEEK,
      show_weekends: DEFAULT_SHOW_WEEKENDS,
      show_week_numbers: DEFAULT_SHOW_WEEK_NUMBERS,
    }
  }
}

impl TryInto<CalendarSettingsParams> for CalendarSettingsPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CalendarSettingsParams, Self::Error> {
    Ok(CalendarSettingsParams {
      layout_ty: self.layout_ty,
      first_day_of_week: self.first_day_of_week,
      show_weekends: self.show_weekends,
      show_week_numbers: self.show_week_numbers,
    })
  }
}

#[derive(Debug, Clone, Eq, PartialEq, Default, ProtoBuf_Enum, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum CalendarLayout {
  #[default]
  MonthLayout = 0,
  WeekLayout = 1,
  DayLayout = 2,
}
