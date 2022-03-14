use crate::impl_from_and_to_type_option;
use crate::services::row::StringifyCellData;
use crate::services::util::*;
use chrono::format::strftime::StrftimeItems;
use chrono::NaiveDateTime;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{Field, FieldType};
use serde::{Deserialize, Serialize};

// Date
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct DateDescription {
    #[pb(index = 1)]
    pub date_format: DateFormat,

    #[pb(index = 2)]
    pub time_format: TimeFormat,
}
impl_from_and_to_type_option!(DateDescription, FieldType::DateTime);

impl DateDescription {
    fn date_time_format_str(&self) -> String {
        format!("{} {}", self.date_format.format_str(), self.time_format.format_str())
    }

    #[allow(dead_code)]
    fn today_from_timestamp(&self, timestamp: i64) -> String {
        let native = chrono::NaiveDateTime::from_timestamp(timestamp, 0);
        self.today_from_native(native)
    }

    fn today_from_native(&self, naive: chrono::NaiveDateTime) -> String {
        let utc: chrono::DateTime<chrono::Utc> = chrono::DateTime::from_utc(naive, chrono::Utc);
        let local: chrono::DateTime<chrono::Local> = chrono::DateTime::from(utc);

        let fmt_str = self.date_time_format_str();
        let output = format!("{}", local.format_with_items(StrftimeItems::new(&fmt_str)));
        output
    }
}

impl StringifyCellData for DateDescription {
    fn str_from_cell_data(&self, data: String) -> String {
        match data.parse::<i64>() {
            Ok(timestamp) => {
                let native = NaiveDateTime::from_timestamp(timestamp, 0);
                self.today_from_native(native)
            }
            Err(e) => {
                tracing::debug!("DateDescription format {} fail. error: {:?}", data, e);
                String::new()
            }
        }
    }

    fn str_to_cell_data(&self, s: &str) -> Result<String, FlowyError> {
        let timestamp = s
            .parse::<i64>()
            .map_err(|e| FlowyError::internal().context(format!("Parse {} to i64 failed: {}", s, e)))?;
        Ok(format!("{}", timestamp))
    }
}

#[derive(Clone, Debug, Copy, Serialize, Deserialize, ProtoBuf_Enum)]
pub enum DateFormat {
    Local = 0,
    US = 1,
    ISO = 2,
    Friendly = 3,
}
impl std::default::Default for DateFormat {
    fn default() -> Self {
        DateFormat::Friendly
    }
}

impl std::convert::From<i32> for DateFormat {
    fn from(value: i32) -> Self {
        match value {
            0 => DateFormat::Local,
            1 => DateFormat::US,
            2 => DateFormat::ISO,
            3 => DateFormat::Friendly,
            _ => {
                tracing::error!("Unsupported date format, fallback to friendly");
                DateFormat::Friendly
            }
        }
    }
}

impl DateFormat {
    pub fn value(&self) -> i32 {
        *self as i32
    }
    // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
    pub fn format_str(&self) -> &'static str {
        match self {
            DateFormat::Local => "%Y/%m/%d",
            DateFormat::US => "%Y/%m/%d",
            DateFormat::ISO => "%Y-%m-%d",
            DateFormat::Friendly => "%b %d,%Y",
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, Serialize, Deserialize, ProtoBuf_Enum)]
pub enum TimeFormat {
    TwelveHour = 0,
    TwentyFourHour = 1,
}

impl std::convert::From<i32> for TimeFormat {
    fn from(value: i32) -> Self {
        match value {
            0 => TimeFormat::TwelveHour,
            1 => TimeFormat::TwentyFourHour,
            _ => {
                tracing::error!("Unsupported time format, fallback to TwentyFourHour");
                TimeFormat::TwentyFourHour
            }
        }
    }
}

impl TimeFormat {
    pub fn value(&self) -> i32 {
        *self as i32
    }

    // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
    pub fn format_str(&self) -> &'static str {
        match self {
            TimeFormat::TwelveHour => "%r",
            TimeFormat::TwentyFourHour => "%R",
        }
    }
}

impl std::default::Default for TimeFormat {
    fn default() -> Self {
        TimeFormat::TwentyFourHour
    }
}
