use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};

#[derive(Debug, Clone, Eq, PartialEq, Default, ProtoBuf)]
pub struct CalendarLayoutSettingsPB {
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
pub struct CalendarLayoutSettingsParams {
  layout_ty: CalendarLayout,
  first_day_of_week: i32,
  show_weekends: bool,
  show_week_numbers: bool,
}

const DEFAULT_FIRST_DAY_OF_WEEK: i32 = 0;
const DEFAULT_SHOW_WEEKENDS: bool = true;
const DEFAULT_SHOW_WEEK_NUMBERS: bool = true;

impl std::default::Default for CalendarLayoutSettingsParams {
  fn default() -> Self {
    CalendarLayoutSettingsParams {
      layout_ty: CalendarLayout::default(),
      first_day_of_week: DEFAULT_FIRST_DAY_OF_WEEK,
      show_weekends: DEFAULT_SHOW_WEEKENDS,
      show_week_numbers: DEFAULT_SHOW_WEEK_NUMBERS,
    }
  }
}

impl std::convert::From<CalendarLayoutSettingsPB> for CalendarLayoutSettingsParams {
  fn from(pb: CalendarLayoutSettingsPB) -> Self {
    CalendarLayoutSettingsParams {
      layout_ty: pb.layout_ty,
      first_day_of_week: pb.first_day_of_week,
      show_weekends: pb.show_weekends,
      show_week_numbers: pb.show_week_numbers,
    }
  }
}

impl std::convert::From<CalendarLayoutSettingsParams> for CalendarLayoutSettingsPB {
  fn from(params: CalendarLayoutSettingsParams) -> Self {
    CalendarLayoutSettingsPB {
      layout_ty: params.layout_ty,
      first_day_of_week: params.first_day_of_week,
      show_weekends: params.show_weekends,
      show_week_numbers: params.show_week_numbers,
    }
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
