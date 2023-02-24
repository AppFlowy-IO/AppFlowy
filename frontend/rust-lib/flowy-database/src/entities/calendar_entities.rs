use crate::entities::parser::NotEmptyStr;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};
use std::convert::TryInto;

#[derive(Debug, Clone, Eq, PartialEq, Default, ProtoBuf)]
pub struct CalendarSettingsPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub layout_ty: CalendarLayout,

  #[pb(index = 3)]
  pub first_day_of_week: i32,

  #[pb(index = 4)]
  pub show_weekends: bool,

  #[pb(index = 5)]
  pub show_week_numbers: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarSettingsParams {
  pub(crate) view_id: String,
  layout_ty: CalendarLayout,
  first_day_of_week: i32,
  show_weekends: bool,
  show_week_numbers: bool,
}

const DEFAULT_FIRST_DAY_OF_WEEK: i32 = 0;
const DEFAULT_SHOW_WEEKENDS: bool = true;
const DEFAULT_SHOW_WEEK_NUMBERS: bool = true;

impl CalendarSettingsParams {
  pub fn default_with(view_id: String) -> Self {
    CalendarSettingsParams {
      view_id: view_id.to_string(),
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
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::ViewIdIsInvalid)?;
    Ok(CalendarSettingsParams {
      view_id: view_id.0,
      layout_ty: self.layout_ty,
      first_day_of_week: self.first_day_of_week,
      show_weekends: self.show_weekends,
      show_week_numbers: self.show_week_numbers,
    })
  }
}

impl std::convert::From<CalendarSettingsParams> for CalendarSettingsPB {
  fn from(params: CalendarSettingsParams) -> Self {
    CalendarSettingsPB {
      view_id: params.view_id,
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
