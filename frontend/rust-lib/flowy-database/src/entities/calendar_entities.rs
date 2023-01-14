use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
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

#[derive(Debug, Clone, Default, ProtoBuf_Enum)]
#[repr(u8)]
pub enum CalendarViewLayout {
  #[default]
  MonthLayout = 0,
  WeekLayout = 1,
  DayLayout = 2,
}
