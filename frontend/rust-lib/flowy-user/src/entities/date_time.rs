use serde::{Deserialize, Serialize};

use flowy_derive::ProtoBuf_Enum;

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Debug, Clone, Default, Copy)]
pub enum UserDateFormatPB {
  Locally = 0,
  US = 1,
  ISO = 2,
  #[default]
  Friendly = 3,
  DayMonthYear = 4,
}

impl std::convert::From<i64> for UserDateFormatPB {
  fn from(value: i64) -> Self {
    match value {
      0 => UserDateFormatPB::Locally,
      1 => UserDateFormatPB::US,
      2 => UserDateFormatPB::ISO,
      3 => UserDateFormatPB::Friendly,
      4 => UserDateFormatPB::DayMonthYear,
      _ => {
        tracing::error!("Unsupported date format, fallback to friendly");
        UserDateFormatPB::Friendly
      },
    }
  }
}

impl UserDateFormatPB {
  pub fn value(&self) -> i64 {
    *self as i64
  }
  // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
  pub fn format_str(&self) -> &'static str {
    match self {
      UserDateFormatPB::Locally => "%m/%d/%Y",
      UserDateFormatPB::US => "%Y/%m/%d",
      UserDateFormatPB::ISO => "%Y-%m-%d",
      UserDateFormatPB::Friendly => "%b %d, %Y",
      UserDateFormatPB::DayMonthYear => "%d/%m/%Y",
    }
  }
}

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Debug, Clone, Default, Copy)]
pub enum UserTimeFormatPB {
  TwelveHour = 0,
  #[default]
  TwentyFourHour = 1,
}

impl std::convert::From<i64> for UserTimeFormatPB {
  fn from(value: i64) -> Self {
    match value {
      0 => UserTimeFormatPB::TwelveHour,
      1 => UserTimeFormatPB::TwentyFourHour,
      _ => {
        tracing::error!("Unsupported time format, fallback to TwentyFourHour");
        UserTimeFormatPB::TwentyFourHour
      },
    }
  }
}

impl UserTimeFormatPB {
  pub fn value(&self) -> i64 {
    *self as i64
  }

  // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
  pub fn format_str(&self) -> &'static str {
    match self {
      UserTimeFormatPB::TwelveHour => "%I:%M %p",
      UserTimeFormatPB::TwentyFourHour => "%R",
    }
  }
}
