use crate::entities::CellChangesetPB;
use crate::entities::{GridCellIdParams, GridCellIdPB};
use crate::services::cell::{CellBytesParser, FromCellChangeset, FromCellString};
use bytes::Bytes;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{internal_error, ErrorCode, FlowyResult};

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
pub struct DateChangesetPayloadPB {
    #[pb(index = 1)]
    pub cell_identifier: GridCellIdPB,

    #[pb(index = 2, one_of)]
    pub date: Option<String>,

    #[pb(index = 3, one_of)]
    pub time: Option<String>,
}

pub struct DateChangesetParams {
    pub cell_identifier: GridCellIdParams,
    pub date: Option<String>,
    pub time: Option<String>,
}

impl TryInto<DateChangesetParams> for DateChangesetPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<DateChangesetParams, Self::Error> {
        let cell_identifier: GridCellIdParams = self.cell_identifier.try_into()?;
        Ok(DateChangesetParams {
            cell_identifier,
            date: self.date,
            time: self.time,
        })
    }
}

impl std::convert::From<DateChangesetParams> for CellChangesetPB {
    fn from(params: DateChangesetParams) -> Self {
        let changeset = DateCellChangesetPB {
            date: params.date,
            time: params.time,
        };
        let s = serde_json::to_string(&changeset).unwrap();
        CellChangesetPB {
            grid_id: params.cell_identifier.grid_id,
            row_id: params.cell_identifier.row_id,
            field_id: params.cell_identifier.field_id,
            content: Some(s),
        }
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DateCellChangesetPB {
    pub date: Option<String>,
    pub time: Option<String>,
}

impl DateCellChangesetPB {
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

impl FromCellChangeset for DateCellChangesetPB {
    fn from_changeset(changeset: String) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        serde_json::from_str::<DateCellChangesetPB>(&changeset).map_err(internal_error)
    }
}
pub struct DateTimestamp(i64);
impl AsRef<i64> for DateTimestamp {
    fn as_ref(&self) -> &i64 {
        &self.0
    }
}

impl std::convert::From<DateTimestamp> for i64 {
    fn from(timestamp: DateTimestamp) -> Self {
        timestamp.0
    }
}

impl FromCellString for DateTimestamp {
    fn from_cell_str(s: &str) -> FlowyResult<Self>
    where
        Self: Sized,
    {
        let num = s.parse::<i64>().unwrap_or(0);
        Ok(DateTimestamp(num))
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
            DateFormat::Local => "%Y/%m/%d",
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

pub struct DateCellDataParser();
impl CellBytesParser for DateCellDataParser {
    type Object = DateCellDataPB;

    fn parse(&self, bytes: &Bytes) -> FlowyResult<Self::Object> {
        DateCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
    }
}
