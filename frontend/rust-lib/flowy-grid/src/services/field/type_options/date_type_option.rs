use crate::entities::{CellIdentifier, CellIdentifierPayload};
use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{
    CellContentChangeset, CellDataOperation, DecodedCellData, EncodedCellData, TypeOptionCellData,
};
use bytes::Bytes;
use chrono::format::strftime::StrftimeItems;
use chrono::NaiveDateTime;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellChangeset, CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
use serde::{Deserialize, Serialize};
use std::str::FromStr;
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
    fn today_desc_from_timestamp(&self, timestamp: i64, time: &Option<String>) -> String {
        let native = chrono::NaiveDateTime::from_timestamp(timestamp, 0);
        self.today_desc_from_native(native, time)
    }

    #[allow(dead_code)]
    fn today_desc_from_str(&self, s: String, time: &Option<String>) -> String {
        match NaiveDateTime::parse_from_str(&s, &self.date_fmt(time)) {
            Ok(native) => self.today_desc_from_native(native, time),
            Err(_) => "".to_owned(),
        }
    }

    fn today_desc_from_native(&self, native: chrono::NaiveDateTime, time: &Option<String>) -> String {
        let utc = self.utc_date_time_from_native(native);
        // let china_timezone = FixedOffset::east(8 * 3600);
        // let a = utc.with_timezone(&china_timezone);
        let fmt = self.date_fmt(time);
        let output = format!("{}", utc.format_with_items(StrftimeItems::new(&fmt)));
        output
    }

    fn utc_date_time_from_timestamp(&self, timestamp: i64) -> chrono::DateTime<chrono::Utc> {
        let native = NaiveDateTime::from_timestamp(timestamp, 0);
        self.utc_date_time_from_native(native)
    }

    fn utc_date_time_from_native(&self, naive: chrono::NaiveDateTime) -> chrono::DateTime<chrono::Utc> {
        chrono::DateTime::<chrono::Utc>::from_utc(naive, chrono::Utc)
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

    pub fn make_date_cell_data(&self, cell_meta: &Option<CellMeta>) -> FlowyResult<DateCellData> {
        if cell_meta.is_none() {
            return Ok(DateCellData::default());
        }

        let json = &cell_meta.as_ref().unwrap().data;
        let result = TypeOptionCellData::from_str(json);
        if result.is_err() {
            return Ok(DateCellData::default());
        }

        let serde_cell_data = DateCellDataSerde::from_str(&result.unwrap().data)?;
        let date = self.decode_cell_data_from_timestamp(&serde_cell_data).content;
        let time = serde_cell_data.time.unwrap_or_else(|| "".to_owned());
        let timestamp = serde_cell_data.timestamp;

        Ok(DateCellData { date, time, timestamp })
    }

    fn decode_cell_data_from_timestamp(&self, serde_cell_data: &DateCellDataSerde) -> DecodedCellData {
        if serde_cell_data.timestamp == 0 {
            return DecodedCellData::default();
        }

        let cell_content = self.today_desc_from_timestamp(serde_cell_data.timestamp, &serde_cell_data.time);
        DecodedCellData::new(serde_cell_data.timestamp.to_string(), cell_content)
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
}

impl CellDataOperation<EncodedCellData<DateCellDataSerde>, DateCellDataSerde> for DateTypeOption {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        _field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<EncodedCellData<DateCellDataSerde>>,
    {
        // Return default data if the type_option_cell_data is not FieldType::DateTime.
        // It happens when switching from one field to another.
        // For example:
        // FieldType::RichText -> FieldType::DateTime, it will display empty content on the screen.
        if !decoded_field_type.is_date() {
            return Ok(DecodedCellData::default());
        }

        let encoded_data = encoded_data.into().try_into_inner()?;
        Ok(self.decode_cell_data_from_timestamp(&encoded_data))
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_meta: Option<CellMeta>) -> Result<DateCellDataSerde, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let content_changeset: DateCellContentChangeset = serde_json::from_str(&changeset.into())?;
        let cell_data = match content_changeset.date_timestamp() {
            None => DateCellDataSerde::default(),
            Some(date_timestamp) => match (self.include_time, content_changeset.time) {
                (true, Some(time)) => {
                    let time = Some(time.trim().to_uppercase());
                    let utc = self.utc_date_time_from_timestamp(date_timestamp);
                    let timestamp = self.timestamp_from_utc_with_time(&utc, &time)?;
                    DateCellDataSerde::new(timestamp, time, &self.time_format)
                }
                _ => DateCellDataSerde::from_timestamp(date_timestamp, Some(default_time_str(&self.time_format))),
            },
        };

        Ok(cell_data)
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
        self.0.field_type()
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

#[derive(Default, Serialize, Deserialize)]
pub struct DateCellDataSerde {
    pub timestamp: i64,
    pub time: Option<String>,
}

impl DateCellDataSerde {
    fn new(timestamp: i64, time: Option<String>, time_format: &TimeFormat) -> Self {
        Self {
            timestamp,
            time: Some(time.unwrap_or_else(|| default_time_str(time_format))),
        }
    }

    pub(crate) fn from_timestamp(timestamp: i64, time: Option<String>) -> Self {
        Self { timestamp, time }
    }
}

impl FromStr for DateCellDataSerde {
    type Err = FlowyError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str::<DateCellDataSerde>(s).map_err(internal_error)
    }
}

impl ToString for DateCellDataSerde {
    fn to_string(&self) -> String {
        serde_json::to_string(&self).unwrap_or_else(|_| "".to_string())
    }
}

fn default_time_str(time_format: &TimeFormat) -> String {
    match time_format {
        TimeFormat::TwelveHour => "12:00 AM".to_string(),
        TimeFormat::TwentyFourHour => "00:00".to_string(),
    }
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
        let changeset = DateCellContentChangeset {
            date: params.date,
            time: params.time,
        };
        let s = serde_json::to_string(&changeset).unwrap();
        CellChangeset {
            grid_id: params.cell_identifier.grid_id,
            row_id: params.cell_identifier.row_id,
            field_id: params.cell_identifier.field_id,
            cell_content_changeset: Some(s),
        }
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DateCellContentChangeset {
    pub date: Option<String>,
    pub time: Option<String>,
}

impl DateCellContentChangeset {
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

impl std::convert::From<DateCellContentChangeset> for CellContentChangeset {
    fn from(changeset: DateCellContentChangeset) -> Self {
        let s = serde_json::to_string(&changeset).unwrap();
        CellContentChangeset::from(s)
    }
}

#[cfg(test)]
mod tests {
    use crate::services::field::FieldBuilder;
    use crate::services::field::{DateCellContentChangeset, DateCellDataSerde, DateFormat, DateTypeOption, TimeFormat};
    use crate::services::row::{
        apply_cell_data_changeset, decode_cell_data_from_type_option_cell_data, CellDataOperation, EncodedCellData,
    };
    use flowy_grid_data_model::entities::{FieldMeta, FieldType};
    use strum::IntoEnumIterator;

    #[test]
    fn date_description_invalid_input_test() {
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        let data = apply_cell_data_changeset("1e", None, &field_meta).unwrap();
        assert_eq!(
            decode_cell_data_from_type_option_cell_data(data, &field_meta, &field_meta.field_type).content,
            "".to_owned()
        );
    }

    #[test]
    fn date_description_date_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        for date_format in DateFormat::iter() {
            type_option.date_format = date_format;
            match date_format {
                DateFormat::Friendly => {
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option
                            .decode_cell_data(data(1647251762), &FieldType::DateTime, &field_meta)
                            .unwrap()
                            .content
                    );
                }
                DateFormat::US => {
                    assert_eq!(
                        "2022/03/14".to_owned(),
                        type_option
                            .decode_cell_data(data(1647251762), &FieldType::DateTime, &field_meta)
                            .unwrap()
                            .content
                    );
                }
                DateFormat::ISO => {
                    assert_eq!(
                        "2022-03-14".to_owned(),
                        type_option
                            .decode_cell_data(data(1647251762), &FieldType::DateTime, &field_meta)
                            .unwrap()
                            .content
                    );
                }
                DateFormat::Local => {
                    assert_eq!(
                        "2022/03/14".to_owned(),
                        type_option
                            .decode_cell_data(data(1647251762), &FieldType::DateTime, &field_meta)
                            .unwrap()
                            .content
                    );
                }
            }
        }
    }

    #[test]
    fn date_description_time_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        for time_format in TimeFormat::iter() {
            type_option.time_format = time_format;
            match time_format {
                TimeFormat::TwentyFourHour => {
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option.today_desc_from_timestamp(1647251762, &None)
                    );
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option
                            .decode_cell_data(data(1647251762), &FieldType::DateTime, &field_meta)
                            .unwrap()
                            .content
                    );
                }
                TimeFormat::TwelveHour => {
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option.today_desc_from_timestamp(1647251762, &None)
                    );
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option
                            .decode_cell_data(data(1647251762), &FieldType::DateTime, &field_meta)
                            .unwrap()
                            .content
                    );
                }
            }
        }
    }

    #[test]
    fn date_description_time_format_test2() {
        let mut type_option = DateTypeOption::default();
        let field_type = FieldType::DateTime;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();

        for time_format in TimeFormat::iter() {
            type_option.time_format = time_format;
            type_option.include_time = true;
            match time_format {
                TimeFormat::TwentyFourHour => {
                    assert_result(
                        &type_option,
                        DateCellContentChangeset {
                            date: Some(1653609600.to_string()),
                            time: None,
                        },
                        &field_type,
                        &field_meta,
                        "May 27,2022 00:00",
                    );
                    assert_result(
                        &type_option,
                        DateCellContentChangeset {
                            date: Some(1653609600.to_string()),
                            time: Some("23:00".to_owned()),
                        },
                        &field_type,
                        &field_meta,
                        "May 27,2022 23:00",
                    );
                }
                TimeFormat::TwelveHour => {
                    assert_result(
                        &type_option,
                        DateCellContentChangeset {
                            date: Some(1653609600.to_string()),
                            time: None,
                        },
                        &field_type,
                        &field_meta,
                        "May 27,2022 12:00 AM",
                    );

                    assert_result(
                        &type_option,
                        DateCellContentChangeset {
                            date: Some(1653609600.to_string()),
                            time: Some("".to_owned()),
                        },
                        &field_type,
                        &field_meta,
                        "May 27,2022",
                    );

                    assert_result(
                        &type_option,
                        DateCellContentChangeset {
                            date: Some(1653609600.to_string()),
                            time: Some("11:23 pm".to_owned()),
                        },
                        &field_type,
                        &field_meta,
                        "May 27,2022 11:23 PM",
                    );
                }
            }
        }
    }

    #[test]
    fn date_description_apply_changeset_test() {
        let mut type_option = DateTypeOption::default();
        let field_type = FieldType::DateTime;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();
        let date_timestamp = "1653609600".to_owned();

        assert_result(
            &type_option,
            DateCellContentChangeset {
                date: Some(date_timestamp.clone()),
                time: None,
            },
            &field_type,
            &field_meta,
            "May 27,2022",
        );

        type_option.include_time = true;
        assert_result(
            &type_option,
            DateCellContentChangeset {
                date: Some(date_timestamp.clone()),
                time: None,
            },
            &field_type,
            &field_meta,
            "May 27,2022 00:00",
        );

        assert_result(
            &type_option,
            DateCellContentChangeset {
                date: Some(date_timestamp.clone()),
                time: Some("1:00".to_owned()),
            },
            &field_type,
            &field_meta,
            "May 27,2022 01:00",
        );

        type_option.time_format = TimeFormat::TwelveHour;
        assert_result(
            &type_option,
            DateCellContentChangeset {
                date: Some(date_timestamp),
                time: Some("1:00 am".to_owned()),
            },
            &field_type,
            &field_meta,
            "May 27,2022 01:00 AM",
        );
    }

    #[test]
    #[should_panic]
    fn date_description_apply_changeset_error_test() {
        let mut type_option = DateTypeOption::default();
        type_option.include_time = true;
        let _field_meta = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        let date_timestamp = "1653609600".to_owned();

        let changeset = DateCellContentChangeset {
            date: Some(date_timestamp.clone()),
            time: Some("1:a0".to_owned()),
        };
        let _ = type_option.apply_changeset(changeset, None).unwrap();

        let changeset = DateCellContentChangeset {
            date: Some(date_timestamp),
            time: Some("1:".to_owned()),
        };
        let _ = type_option.apply_changeset(changeset, None).unwrap();
    }

    #[test]
    #[should_panic]
    fn date_description_invalid_data_test() {
        let type_option = DateTypeOption::default();
        type_option.apply_changeset("he", None).unwrap();
    }

    fn data(s: i64) -> String {
        serde_json::to_string(&DateCellDataSerde::from_timestamp(s, None)).unwrap()
    }

    fn assert_result(
        type_option: &DateTypeOption,
        changeset: DateCellContentChangeset,
        field_type: &FieldType,
        field_meta: &FieldMeta,
        expected: &str,
    ) {
        let encoded_data = EncodedCellData(Some(type_option.apply_changeset(changeset, None).unwrap()));
        let content = type_option
            .decode_cell_data(encoded_data, field_type, field_meta)
            .unwrap()
            .content;
        assert_eq!(expected.to_owned(), content);
    }
}
