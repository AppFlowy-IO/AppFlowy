use crate::impl_type_option;
use crate::services::row::{CellDataChangeset, CellDataOperation, TypeOptionCellData};
use bytes::Bytes;
use chrono::format::strftime::StrftimeItems;
use chrono::NaiveDateTime;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{CellMeta, FieldMeta, FieldType, TypeOptionDataEntity, TypeOptionDataEntry};
use serde::{Deserialize, Serialize};
use std::str::FromStr;

use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use strum_macros::EnumIter;

// Date
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct DateTypeOption {
    #[pb(index = 1)]
    pub date_format: DateFormat,

    #[pb(index = 2)]
    pub time_format: TimeFormat,
}
impl_type_option!(DateTypeOption, FieldType::DateTime);

impl DateTypeOption {
    #[allow(dead_code)]
    fn today_from_timestamp(&self, timestamp: i64) -> String {
        let native = chrono::NaiveDateTime::from_timestamp(timestamp, 0);
        self.today_from_native(native)
    }

    fn today_from_native(&self, naive: chrono::NaiveDateTime) -> String {
        let utc: chrono::DateTime<chrono::Utc> = chrono::DateTime::from_utc(naive, chrono::Utc);
        let local: chrono::DateTime<chrono::Local> = chrono::DateTime::from(utc);
        let output = format!("{}", local.format_with_items(StrftimeItems::new(&self.fmt_str())));
        output
    }

    fn fmt_str(&self) -> String {
        format!("{} {}", self.date_format.format_str(), self.time_format.format_str())
    }
}

impl CellDataOperation for DateTypeOption {
    fn decode_cell_data(&self, data: String, _field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if !type_option_cell_data.is_date() {
                return String::new();
            }

            let cell_data = type_option_cell_data.data;
            if let Ok(timestamp) = cell_data.parse::<i64>() {
                let native = NaiveDateTime::from_timestamp(timestamp, 0);
                return self.today_from_native(native);
            }

            if NaiveDateTime::parse_from_str(&cell_data, &self.fmt_str()).is_ok() {
                return cell_data;
            }
        }

        String::new()
    }

    fn apply_changeset<T: Into<CellDataChangeset>>(
        &self,
        changeset: T,
        _cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.into();
        if let Err(e) = changeset.parse::<i64>() {
            tracing::error!("Parse {} to i64 failed: {}", changeset.to_string(), e);
            return Err(FlowyError::internal().context(e));
        };

        Ok(TypeOptionCellData::new(changeset, self.field_type()).json())
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

#[cfg(test)]
mod tests {
    use crate::services::field::FieldBuilder;
    use crate::services::field::{DateFormat, DateTypeOption, TimeFormat};
    use crate::services::row::{CellDataOperation, TypeOptionCellData};
    use flowy_grid_data_model::entities::FieldType;
    use strum::IntoEnumIterator;

    #[test]
    fn date_description_invalid_input_test() {
        let type_option = DateTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        assert_eq!(
            "".to_owned(),
            type_option.decode_cell_data("1e".to_owned(), &field_meta)
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
                        "Mar 14,2022 17:56".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta)
                    );
                    assert_eq!(
                        "Mar 14,2022 17:56".to_owned(),
                        type_option.decode_cell_data(data("Mar 14,2022 17:56"), &field_meta)
                    );
                }
                DateFormat::US => {
                    assert_eq!(
                        "2022/03/14 17:56".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta)
                    );
                    assert_eq!(
                        "2022/03/14 17:56".to_owned(),
                        type_option.decode_cell_data(data("2022/03/14 17:56"), &field_meta)
                    );
                }
                DateFormat::ISO => {
                    assert_eq!(
                        "2022-03-14 17:56".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta)
                    );
                }
                DateFormat::Local => {
                    assert_eq!(
                        "2022/03/14 17:56".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta)
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
                        "Mar 14,2022 17:56".to_owned(),
                        type_option.today_from_timestamp(1647251762)
                    );
                    assert_eq!(
                        "Mar 14,2022 17:56".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta)
                    );
                }
                TimeFormat::TwelveHour => {
                    assert_eq!(
                        "Mar 14,2022 05:56:02 PM".to_owned(),
                        type_option.today_from_timestamp(1647251762)
                    );
                    assert_eq!(
                        "Mar 14,2022 05:56:02 PM".to_owned(),
                        type_option.decode_cell_data(data("1647251762"), &field_meta)
                    );
                }
            }
        }
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
