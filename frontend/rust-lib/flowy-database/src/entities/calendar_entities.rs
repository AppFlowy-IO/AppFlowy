use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use serde::{Deserialize, Serialize};
use std::convert::TryInto;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CalendarSettingsPB {
  #[pb(index = 1)]
  pub current_layout: CalendarViewLayout,

  #[pb(index = 2)]
  pub first_day_of_week: i32,

  #[pb(index = 3)]
  pub show_weekends: bool,

  #[pb(index = 4)]
  pub show_week_number: bool,
}

// impl TryInto<CalendarSettingsParams> for CalendarSettingsPB {
//   type Error = ErrorCode;

// }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarSettingsParams {}

impl std::default::Default for CalendarSettings {
    // The default settings will be used if there is no existing settings
    fn default() -> Self {
        todo!()
    }
}

#[derive(Debug, Clone, Default, ProtoBuf_Enum)]
#[repr(u8)]
pub enum CalendarViewLayout {
  #[default]
  MonthLayout = 0,
  WeekLayout = 1,
  DayLayout = 2,
}
