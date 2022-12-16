use crate::entities::CellPathPB;
use crate::services::cell::{CellBytesParser, DecodedCellData, FromCellChangeset, FromCellString};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{internal_error, FlowyResult};
use serde::{Deserialize, Serialize};
use strum_macros::EnumIter;

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateCellDataPB {
    #[pb(index = 1)]
    pub date: String,

    #[pb(index = 2)]
    pub time: String,

    #[pb(index = 3)]
    pub timestamp: i64,
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateChangesetPB {
    #[pb(index = 1)]
    pub cell_path: CellPathPB,

    #[pb(index = 2, one_of)]
    pub date: Option<String>,

    #[pb(index = 3, one_of)]
    pub time: Option<String>,

    #[pb(index = 4)]
    pub is_utc: bool,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DateCellChangeset {
    pub date: Option<String>,
    pub time: Option<String>,
    pub is_utc: bool,
}

impl DateCellChangeset {
    pub fn date_timestamp(&self) -> Option<i64> {
        if let Some(date) = &self.date {
            match date.parse::<i64>() {
                Ok(date_timestamp) => Some(date_timestamp),
                Err(_) => None,
            }
        } else {
            None
        }
    }
}

impl FromCellChangeset for DateCellChangeset {
    fn from_changeset(changeset: String) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        serde_json::from_str::<DateCellChangeset>(&changeset).map_err(internal_error)
    }
}

impl ToString for DateCellChangeset {
    fn to_string(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_string())
    }
}

pub struct DateCellData(pub Option<i64>);

impl std::convert::From<DateCellData> for i64 {
    fn from(timestamp: DateCellData) -> Self {
        timestamp.0.unwrap_or(0)
    }
}

impl std::convert::From<DateCellData> for Option<i64> {
    fn from(timestamp: DateCellData) -> Self {
        timestamp.0
    }
}

impl FromCellString for DateCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        let num = s.parse::<i64>().ok();
        Ok(DateCellData(num))
    }
}

#[derive(Clone, Debug, Copy, EnumIter, Serialize, Deserialize, ProtoBuf_Enum)]
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
            DateFormat::Local => "%m/%d/%Y",
            DateFormat::US => "%Y/%m/%d",
            DateFormat::ISO => "%Y-%m-%d",
            DateFormat::Friendly => "%b %d,%Y",
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, EnumIter, Debug, Hash, Serialize, Deserialize, ProtoBuf_Enum)]
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
            TimeFormat::TwelveHour => "%I:%M %p",
            TimeFormat::TwentyFourHour => "%R",
        }
    }
}

impl std::default::Default for TimeFormat {
    fn default() -> Self {
        TimeFormat::TwentyFourHour
    }
}

impl DecodedCellData for DateCellDataPB {
    type Object = DateCellDataPB;

    fn is_empty(&self) -> bool {
        self.date.is_empty()
    }
}

pub struct DateCellDataParser();
impl CellBytesParser for DateCellDataParser {
    type Object = DateCellDataPB;

    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        DateCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
    }
}
