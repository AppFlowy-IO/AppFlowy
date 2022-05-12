use crate::impl_type_option;
use crate::services::entities::{CellIdentifier, CellIdentifierPayload};
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellContentChangeset, CellDataOperation, DecodedCellData, TypeOptionCellData};
use bytes::Bytes;
use chrono::format::strftime::StrftimeItems;
use chrono::NaiveDateTime;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellChangeset, CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
use serde::{Deserialize, Serialize};
use std::ops::Add;
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
    #[allow(dead_code)]
    fn today_desc_from_timestamp(&self, timestamp: i64) -> String {
        let native = chrono::NaiveDateTime::from_timestamp(timestamp, 0);
        self.today_desc_from_native(native)
    }

    fn today_desc_from_str(&self, s: String) -> String {
        match NaiveDateTime::parse_from_str(&s, &self.fmt_str()) {
            Ok(native) => self.today_desc_from_native(native),
            Err(_) => "".to_owned(),
        }
    }

    fn today_desc_from_native(&self, native: chrono::NaiveDateTime) -> String {
        let utc = self.utc_date_time_from_native(native);
        // let china_timezone = FixedOffset::east(8 * 3600);
        // let a = utc.with_timezone(&china_timezone);
        let output = format!("{}", utc.format_with_items(StrftimeItems::new(&self.fmt_str())));
        output
    }

    fn timestamp_from_str(&self, s: &str) -> FlowyResult<i64> {
        match NaiveDateTime::parse_from_str(s, &self.fmt_str()) {
            Ok(native) => {
                let utc = self.utc_date_time_from_native(native);
                Ok(utc.timestamp())
            }
            Err(_) => Err(ErrorCode::InvalidData.into()),
        }
    }

    fn utc_date_time_from_timestamp(&self, timestamp: i64) -> chrono::DateTime<chrono::Utc> {
        let native = NaiveDateTime::from_timestamp(timestamp, 0);
        self.utc_date_time_from_native(native)
    }

    fn utc_date_time_from_native(&self, naive: chrono::NaiveDateTime) -> chrono::DateTime<chrono::Utc> {
        chrono::DateTime::<chrono::Utc>::from_utc(naive, chrono::Utc)
    }

    fn fmt_str(&self) -> String {
        if self.include_time {
            format!("{} {}", self.date_format.format_str(), self.time_format.format_str())
        } else {
            self.date_format.format_str().to_string()
        }
    }

    pub fn date_cell_data(&self, cell_meta: &Option<CellMeta>) -> FlowyResult<DateCellData> {
        if cell_meta.is_none() {
            return Ok(DateCellData::default());
        }

        let json = &cell_meta.as_ref().unwrap().data;
        let result = TypeOptionCellData::from_str(json);
        if result.is_err() {
            return Ok(DateCellData::default());
        }

        let data: DateCellData = serde_json::from_str(&result.unwrap().data)?;
        Ok(data)
    }
}

impl CellDataOperation for DateTypeOption {
    fn decode_cell_data(&self, data: String, _field_meta: &FieldMeta) -> DecodedCellData {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if !type_option_cell_data.is_date() {
                return DecodedCellData::default();
            }

            let cell_data = type_option_cell_data.data;
            if let Ok(timestamp) = cell_data.parse::<i64>() {
                return DecodedCellData::new(format!("{}", timestamp), self.today_desc_from_timestamp(timestamp));
            }

            let cell_content = self.today_desc_from_str(cell_data.clone());
            return DecodedCellData::new(cell_data, cell_content);
        }

        DecodedCellData::default()
    }

    fn apply_changeset<T: Into<CellContentChangeset>>(
        &self,
        changeset: T,
        _cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError> {
        let content_changeset: DateCellContentChangeset = serde_json::from_str(&changeset.into())?;
        let cell_content = match content_changeset.date_timestamp() {
            None => "".to_owned(),
            Some(date_timestamp) => {
                //
                match (self.include_time, content_changeset.time) {
                    (true, Some(time)) => {
                        let utc = self.utc_date_time_from_timestamp(date_timestamp);
                        let mut date_str = format!(
                            "{}",
                            utc.format_with_items(StrftimeItems::new(self.date_format.format_str()))
                        );
                        date_str = date_str.add(&time);
                        let timestamp = self.timestamp_from_str(&date_str)?;
                        timestamp.to_string()
                    }
                    _ => date_timestamp.to_string(),
                }
            }
        };
        Ok(TypeOptionCellData::new(cell_content, self.field_type()).json())
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

#[derive(Clone, Debug, Default, ProtoBuf, Serialize, Deserialize)]
pub struct DateCellData {
    #[pb(index = 1)]
    pub date: String,

    #[pb(index = 2)]
    pub time: String,
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
    use crate::services::field::{DateCellContentChangeset, DateFormat, DateTypeOption, TimeFormat};
    use crate::services::row::{CellDataOperation, TypeOptionCellData};
    use flowy_grid_data_model::entities::FieldType;
    use strum::IntoEnumIterator;

    #[test]
    fn date_description_invalid_input_test() {
        let type_option = DateTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        assert_eq!(
            "".to_owned(),
            type_option.decode_cell_data("1e".to_owned(), &field_meta).content
        );
    }

    #[test]
    fn date_description_date_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        for date_format in DateFormat::iter() {
            type_option.date_format = date_format;
            match date_format {
                DateFormat::Friendly => {
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta).content
                    );
                    assert_eq!(
                        // "Mar 14,2022".to_owned(),
                        "".to_owned(),
                        type_option
                            .decode_cell_data(data("Mar 14,2022 17:56"), &field_meta)
                            .content
                    );
                }
                DateFormat::US => {
                    assert_eq!(
                        "2022/03/14".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta).content
                    );
                    assert_eq!(
                        // "2022/03/14".to_owned(),
                        "".to_owned(),
                        type_option
                            .decode_cell_data(data("2022/03/14 17:56"), &field_meta)
                            .content
                    );
                }
                DateFormat::ISO => {
                    assert_eq!(
                        "2022-03-14".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta).content
                    );
                }
                DateFormat::Local => {
                    assert_eq!(
                        "2022/03/14".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta).content
                    );
                }
            }
        }
    }

    #[test]
    fn date_description_time_format_test() {
        let mut type_option = DateTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        for time_format in TimeFormat::iter() {
            type_option.time_format = time_format;
            match time_format {
                TimeFormat::TwentyFourHour => {
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option.today_desc_from_timestamp(1647251762)
                    );
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta).content
                    );
                }
                TimeFormat::TwelveHour => {
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option.today_desc_from_timestamp(1647251762)
                    );
                    assert_eq!(
                        "Mar 14,2022".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta).content
                    );
                }
            }
        }
    }

    #[test]
    fn date_description_apply_changeset_test() {
        let mut type_option = DateTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        let date_timestamp = "1653609600".to_owned();

        let changeset = DateCellContentChangeset {
            date: Some(date_timestamp.clone()),
            time: None,
        };
        let result = type_option.apply_changeset(changeset, None).unwrap();
        let content = type_option.decode_cell_data(result.clone(), &field_meta).content;
        assert_eq!(content, "May 27,2022".to_owned());

        type_option.include_time = true;
        let content = type_option.decode_cell_data(result, &field_meta).content;
        assert_eq!(content, "May 27,2022 00:00".to_owned());

        let changeset = DateCellContentChangeset {
            date: Some(date_timestamp.clone()),
            time: Some("1:00".to_owned()),
        };
        let result = type_option.apply_changeset(changeset, None).unwrap();
        let content = type_option.decode_cell_data(result, &field_meta).content;
        assert_eq!(content, "May 27,2022 01:00".to_owned());

        let changeset = DateCellContentChangeset {
            date: Some(date_timestamp),
            time: Some("1:00 am".to_owned()),
        };
        type_option.time_format = TimeFormat::TwelveHour;
        let result = type_option.apply_changeset(changeset, None).unwrap();
        let content = type_option.decode_cell_data(result, &field_meta).content;
        assert_eq!(content, "May 27,2022 01:00 AM".to_owned());
    }

    #[test]
    #[should_panic]
    fn date_description_apply_changeset_error_test() {
        let mut type_option = DateTypeOption::default();
        type_option.include_time = true;
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        let date_timestamp = "1653609600".to_owned();

        let changeset = DateCellContentChangeset {
            date: Some(date_timestamp.clone()),
            time: Some("1:a0".to_owned()),
        };
        let _ = type_option.apply_changeset(changeset, None).unwrap();

        let changeset = DateCellContentChangeset {
            date: Some(date_timestamp.clone()),
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

    fn data(s: &str) -> String {
        TypeOptionCellData::new(s, FieldType::DateTime).json()
    }
}
