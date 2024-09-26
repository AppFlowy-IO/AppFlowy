use collab_database::fields::timestamp_type_option::TimestampTypeOption;
use flowy_derive::ProtoBuf;

use crate::entities::{DateFormatPB, FieldType, TimeFormatPB};

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimestampCellDataPB {
  #[pb(index = 1)]
  pub date_time: String,

  #[pb(index = 2, one_of)]
  pub timestamp: Option<i64>,
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct TimestampTypeOptionPB {
  #[pb(index = 1)]
  pub date_format: DateFormatPB,

  #[pb(index = 2)]
  pub time_format: TimeFormatPB,

  #[pb(index = 3)]
  pub include_time: bool,

  #[pb(index = 4)]
  pub field_type: FieldType,
}

impl From<TimestampTypeOption> for TimestampTypeOptionPB {
  fn from(data: TimestampTypeOption) -> Self {
    Self {
      date_format: data.date_format.into(),
      time_format: data.time_format.into(),
      include_time: data.include_time,
      field_type: data.field_type.into(),
    }
  }
}

impl From<TimestampTypeOptionPB> for TimestampTypeOption {
  fn from(data: TimestampTypeOptionPB) -> Self {
    Self {
      date_format: data.date_format.into(),
      time_format: data.time_format.into(),
      include_time: data.include_time,
      field_type: data.field_type.into(),
    }
  }
}
