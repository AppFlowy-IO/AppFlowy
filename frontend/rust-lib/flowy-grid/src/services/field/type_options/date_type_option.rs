use crate::entities::{CellChangeset, FieldType};
use crate::entities::{CellIdentifier, CellIdentifierPayload};
use crate::impl_type_option;
use crate::services::cell::{
    AnyCellData, CellData, CellDataChangeset, CellDataOperation, DecodedCellData, FromCellChangeset, FromCellString,
};
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use bytes::Bytes;
use chrono::format::strftime::StrftimeItems;
use chrono::{NaiveDateTime, Timelike};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataEntry};
use serde::{Deserialize, Serialize};
use strum_macros::EnumIter;

// Date
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct DateTypeOption {
    #[pb(index = 1)]
    pub date_format: DateFormat,

    #[pb(index = 2)]
    pub time_format: TimeFormat,

    #[pb(index = 3)]
    pub include_time: bool,
}
impl_type_option!(DateTypeOption, FieldType::DateTime);

impl DateTypeOption {
    #[allow(dead_code)]
    pub fn new() -> Self {
        Self::default()
    }

    fn today_desc_from_timestamp(&self, timestamp: i64) -> DateCellData {
        let native = chrono::NaiveDateTime::from_timestamp(timestamp, 0);
        self.date_from_native(native)
    }

    fn date_from_native(&self, native: chrono::NaiveDateTime) -> DateCellData {
        if native.timestamp() == 0 {
            return DateCellData::default();
        }

        let time = native.time();
        let has_time = time.hour() != 0 || time.second() != 0;

        let utc = self.utc_date_time_from_native(native);
        let fmt = self.date_format.format_str();
        let date = format!("{}", utc.format_with_items(StrftimeItems::new(fmt)));

        let mut time = "".to_string();
        if has_time {
            let fmt = format!("{} {}", self.date_format.format_str(), self.time_format.format_str());
            time = format!("{}", utc.format_with_items(StrftimeItems::new(&fmt))).replace(&date, "");
        }

        let timestamp = native.timestamp();
        DateCellData { date, time, timestamp }
    }

    fn date_fmt(&self, time: &Option<String>) -> String {
        if self.include_time {
            match time.as_ref() {
                None => self.date_format.format_str().to_string(),
                Some(time_str) => {
                    if time_str.is_empty() {
                        self.date_format.format_str().to_string()
                    } else {
                        format!("{} {}", self.date_format.format_str(), self.time_format.format_str())
                    }
                }
            }
        } else {
            self.date_format.format_str().to_string()
        }
    }

    fn timestamp_from_utc_with_time(
        &self,
        utc: &chrono::DateTime<chrono::Utc>,
        time: &Option<String>,
    ) -> FlowyResult<i64> {
        if let Some(time_str) = time.as_ref() {
            if !time_str.is_empty() {
                let date_str = format!(
                    "{}{}",
                    utc.format_with_items(StrftimeItems::new(self.date_format.format_str())),
                    &time_str
                );

                return match NaiveDateTime::parse_from_str(&date_str, &self.date_fmt(time)) {
                    Ok(native) => {
                        let utc = self.utc_date_time_from_native(native);
                        Ok(utc.timestamp())
                    }
                    Err(_e) => {
                        let msg = format!("Parse {} failed", date_str);
                        Err(FlowyError::new(ErrorCode::InvalidDateTimeFormat, &msg))
                    }
                };
            }
        }

        Ok(utc.timestamp())
    }

    fn utc_date_time_from_timestamp(&self, timestamp: i64) -> chrono::DateTime<chrono::Utc> {
        let native = NaiveDateTime::from_timestamp(timestamp, 0);
        let native2 = NaiveDateTime::from_timestamp(timestamp, 0);

        if native > native2 {}

        self.utc_date_time_from_native(native)
    }

    fn utc_date_time_from_native(&self, naive: chrono::NaiveDateTime) -> chrono::DateTime<chrono::Utc> {
        chrono::DateTime::<chrono::Utc>::from_utc(naive, chrono::Utc)
    }
}

impl CellDataOperation<DateTimestamp, DateCellChangeset> for DateTypeOption {
    fn decode_cell_data(
        &self,
        cell_data: CellData<DateTimestamp>,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<DecodedCellData> {
        // Return default data if the type_option_cell_data is not FieldType::DateTime.
        // It happens when switching from one field to another.
        // For example:
        // FieldType::RichText -> FieldType::DateTime, it will display empty content on the screen.
        if !decoded_field_type.is_date() {
            return Ok(DecodedCellData::default());
        }
        let timestamp = cell_data.try_into_inner()?;
        let date = self.today_desc_from_timestamp(timestamp.0);
        DecodedCellData::try_from_bytes(date)
    }

    fn apply_changeset(
        &self,
        changeset: CellDataChangeset<DateCellChangeset>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.try_into_inner()?;
        let cell_data = match changeset.date_timestamp() {
            None => 0,
            Some(date_timestamp) => match (self.include_time, changeset.time) {
                (true, Some(time)) => {
                    let time = Some(time.trim().to_uppercase());
                    let utc = self.utc_date_time_from_timestamp(date_timestamp);
                    self.timestamp_from_utc_with_time(&utc, &time)?
                }
                _ => date_timestamp,
            },
        };

        Ok(cell_data.to_string())
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

impl std::convert::From<AnyCellData> for DateTimestamp {
    fn from(data: AnyCellData) -> Self {
        let num = data.data.parse::<i64>().unwrap_or(0);
        DateTimestamp(num)
    }
}

#[derive(Default)]
pub struct DateTypeOptionBuilder(DateTypeOption);
impl_into_box_type_option_builder!(DateTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(DateTypeOptionBuilder, DateTypeOption);

impl DateTypeOptionBuilder {
    pub fn date_format(mut self, date_format: DateFormat) -> Self {
        self.0.date_format = date_format;
        self
    }

    pub fn time_format(mut self, time_format: TimeFormat) -> Self {
        self.0.time_format = time_format;
        self
    }
}
impl TypeOptionBuilder for DateTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::DateTime
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
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

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateCellData {
    #[pb(index = 1)]
    pub date: String,

    #[pb(index = 2)]
    pub time: String,

    #[pb(index = 3)]
    pub timestamp: i64,
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateChangesetPayload {
    #[pb(index = 1)]
    pub cell_identifier: CellIdentifierPayload,

    #[pb(index = 2, one_of)]
    pub date: Option<String>,

    #[pb(index = 3, one_of)]
    pub time: Option<String>,
}

pub struct DateChangesetParams {
    pub cell_identifier: CellIdentifier,
    pub date: Option<String>,
    pub time: Option<String>,
}

impl TryInto<DateChangesetParams> for DateChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<DateChangesetParams, Self::Error> {
        let cell_identifier: CellIdentifier = self.cell_identifier.try_into()?;
        Ok(DateChangesetParams {
            cell_identifier,
            date: self.date,
            time: self.time,
        })
    }
}

impl std::convert::From<DateChangesetParams> for CellChangeset {
    fn from(params: DateChangesetParams) -> Self {
        let changeset = DateCellChangeset {
            date: params.date,
            time: params.time,
        };
        let s = serde_json::to_string(&changeset).unwrap();
        CellChangeset {
            grid_id: params.cell_identifier.grid_id,
            row_id: params.cell_identifier.row_id,
            field_id: params.cell_identifier.field_id,
            content: Some(s),
        }
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DateCellChangeset {
    pub date: Option<String>,
    pub time: Option<String>,
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

#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::{CellDataChangeset, CellDataOperation};
    use crate::services::field::FieldBuilder;
    use crate::services::field::{DateCellChangeset, DateCellData, DateFormat, DateTypeOption, TimeFormat};
    use flowy_grid_data_model::revision::FieldRevision;
    use strum::IntoEnumIterator;

    #[test]
    fn date_type_option_invalid_input_test() {
        let type_option = DateTypeOption::default();
        let field_type = FieldType::DateTime;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some("1e".to_string()),
                time: Some("23:00".to_owned()),
            },
            &field_type,
            &field_rev,
            "",
        );
    }

    #[test]
    fn date_type_option_date_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        for date_format in DateFormat::iter() {
            type_option.date_format = date_format;
            match date_format {
                DateFormat::Friendly => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "Mar 14,2022");
                }
                DateFormat::US => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "2022/03/14");
                }
                DateFormat::ISO => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "2022-03-14");
                }
                DateFormat::Local => {
                    assert_decode_timestamp(1647251762, &type_option, &field_rev, "2022/03/14");
                }
            }
        }
    }

    #[test]
    fn date_type_option_time_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_type = FieldType::DateTime;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for time_format in TimeFormat::iter() {
            type_option.time_format = time_format;
            type_option.include_time = true;
            match time_format {
                TimeFormat::TwentyFourHour => {
                    assert_changeset_result(
                        &type_option,
                        DateCellChangeset {
                            date: Some(1653609600.to_string()),
                            time: None,
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022",
                    );
                    assert_changeset_result(
                        &type_option,
                        DateCellChangeset {
                            date: Some(1653609600.to_string()),
                            time: Some("23:00".to_owned()),
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022 23:00",
                    );
                }
                TimeFormat::TwelveHour => {
                    assert_changeset_result(
                        &type_option,
                        DateCellChangeset {
                            date: Some(1653609600.to_string()),
                            time: None,
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022",
                    );
                    //
                    assert_changeset_result(
                        &type_option,
                        DateCellChangeset {
                            date: Some(1653609600.to_string()),
                            time: Some("".to_owned()),
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022",
                    );

                    assert_changeset_result(
                        &type_option,
                        DateCellChangeset {
                            date: Some(1653609600.to_string()),
                            time: Some("11:23 pm".to_owned()),
                        },
                        &field_type,
                        &field_rev,
                        "May 27,2022 11:23 PM",
                    );
                }
            }
        }
    }

    #[test]
    fn date_type_option_apply_changeset_test() {
        let mut type_option = DateTypeOption::new();
        let field_type = FieldType::DateTime;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        let date_timestamp = "1653609600".to_owned();

        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some(date_timestamp.clone()),
                time: None,
            },
            &field_type,
            &field_rev,
            "May 27,2022",
        );

        type_option.include_time = true;
        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some(date_timestamp.clone()),
                time: None,
            },
            &field_type,
            &field_rev,
            "May 27,2022",
        );

        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some(date_timestamp.clone()),
                time: Some("1:00".to_owned()),
            },
            &field_type,
            &field_rev,
            "May 27,2022 01:00",
        );

        type_option.time_format = TimeFormat::TwelveHour;
        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some(date_timestamp),
                time: Some("1:00 am".to_owned()),
            },
            &field_type,
            &field_rev,
            "May 27,2022 01:00 AM",
        );
    }

    #[test]
    #[should_panic]
    fn date_type_option_apply_changeset_error_test() {
        let mut type_option = DateTypeOption::new();
        type_option.include_time = true;
        let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        let date_timestamp = "1653609600".to_owned();

        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some(date_timestamp.clone()),
                time: Some("1:".to_owned()),
            },
            &FieldType::DateTime,
            &field_rev,
            "May 27,2022 01:00",
        );

        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some(date_timestamp),
                time: Some("1:00".to_owned()),
            },
            &FieldType::DateTime,
            &field_rev,
            "May 27,2022 01:00",
        );
    }

    #[test]
    #[should_panic]
    fn date_type_option_twelve_hours_to_twenty_four_hours() {
        let mut type_option = DateTypeOption::new();
        type_option.include_time = true;
        let field_rev = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        let date_timestamp = "1653609600".to_owned();

        assert_changeset_result(
            &type_option,
            DateCellChangeset {
                date: Some(date_timestamp),
                time: Some("1:00 am".to_owned()),
            },
            &FieldType::DateTime,
            &field_rev,
            "May 27,2022 01:00",
        );
    }

    fn assert_changeset_result(
        type_option: &DateTypeOption,
        changeset: DateCellChangeset,
        _field_type: &FieldType,
        field_rev: &FieldRevision,
        expected: &str,
    ) {
        let changeset = CellDataChangeset(Some(changeset));
        let encoded_data = type_option.apply_changeset(changeset, None).unwrap();
        assert_eq!(
            expected.to_owned(),
            decode_cell_data(encoded_data, type_option, field_rev)
        );
    }

    fn assert_decode_timestamp(
        timestamp: i64,
        type_option: &DateTypeOption,
        field_rev: &FieldRevision,
        expected: &str,
    ) {
        let s = serde_json::to_string(&DateCellChangeset {
            date: Some(timestamp.to_string()),
            time: None,
        })
        .unwrap();
        let encoded_data = type_option.apply_changeset(s.into(), None).unwrap();

        assert_eq!(
            expected.to_owned(),
            decode_cell_data(encoded_data, type_option, field_rev)
        );
    }

    fn decode_cell_data(encoded_data: String, type_option: &DateTypeOption, field_rev: &FieldRevision) -> String {
        let decoded_data = type_option
            .decode_cell_data(encoded_data.into(), &FieldType::DateTime, field_rev)
            .unwrap()
            .parse::<DateCellData>()
            .unwrap();

        if type_option.include_time {
            format!("{}{}", decoded_data.date, decoded_data.time)
        } else {
            decoded_data.date
        }
    }
}
