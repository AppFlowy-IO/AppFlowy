use crate::entities::{DateFilterPB, FieldType};
use crate::impl_type_option;
use crate::services::cell::{AnyCellChangeset, CellBytes, CellDataChangeset, CellDataDecoder, FromCellString};
use crate::services::field::{
    BoxTypeOptionBuilder, DateCellChangeset, DateCellData, DateCellDataPB, DateFormat, TimeFormat, TypeOption,
    TypeOptionBuilder, TypeOptionCellData, TypeOptionConfiguration,
};
use bytes::Bytes;
use chrono::format::strftime::StrftimeItems;
use chrono::{NaiveDateTime, Timelike};
use flowy_derive::ProtoBuf;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use serde::{Deserialize, Serialize};

// Date
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct DateTypeOptionPB {
    #[pb(index = 1)]
    pub date_format: DateFormat,

    #[pb(index = 2)]
    pub time_format: TimeFormat,

    #[pb(index = 3)]
    pub include_time: bool,
}
impl_type_option!(DateTypeOptionPB, FieldType::DateTime);

impl TypeOption for DateTypeOptionPB {
    type CellData = DateCellData;
    type CellChangeset = DateCellChangeset;
    type CellPBType = DateCellDataPB;
}

impl TypeOptionConfiguration for DateTypeOptionPB {
    type CellFilterConfiguration = DateFilterPB;
}

impl TypeOptionCellData for DateTypeOptionPB {
    fn decode_type_option_cell_data(&self, cell_data: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        DateCellData::from_cell_str(&cell_data)
    }
}

impl DateTypeOptionPB {
    #[allow(dead_code)]
    pub fn new() -> Self {
        Self::default()
    }

    fn today_desc_from_timestamp<T: Into<i64>>(&self, timestamp: T) -> DateCellDataPB {
        let timestamp = timestamp.into();
        let native = chrono::NaiveDateTime::from_timestamp(timestamp, 0);
        if native.timestamp() == 0 {
            return DateCellDataPB::default();
        }

        let time = native.time();
        let has_time = time.hour() != 0 || time.second() != 0;

        let utc = self.utc_date_time_from_native(native);
        let fmt = self.date_format.format_str();
        let date = format!("{}", utc.format_with_items(StrftimeItems::new(fmt)));

        let mut time = "".to_string();
        if has_time && self.include_time {
            let fmt = format!("{}{}", self.date_format.format_str(), self.time_format.format_str());
            time = format!("{}", utc.format_with_items(StrftimeItems::new(&fmt))).replace(&date, "");
        }

        let timestamp = native.timestamp();
        DateCellDataPB { date, time, timestamp }
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

    fn utc_date_time_from_native(&self, naive: chrono::NaiveDateTime) -> chrono::DateTime<chrono::Utc> {
        chrono::DateTime::<chrono::Utc>::from_utc(naive, chrono::Utc)
    }
}

impl CellDataDecoder for DateTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: String,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_data = self.decode_type_option_cell_data(cell_data)?;
        let cell_data_pb = self.today_desc_from_timestamp(cell_data);
        CellBytes::from(cell_data_pb)
    }

    fn try_decode_cell_data(
        &self,
        cell_data: String,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        // Return default data if the type_option_cell_data is not FieldType::DateTime.
        // It happens when switching from one field to another.
        // For example:
        // FieldType::RichText -> FieldType::DateTime, it will display empty content on the screen.
        if !decoded_field_type.is_date() {
            return Ok(CellBytes::default());
        }

        self.decode_cell_data(cell_data, decoded_field_type, field_rev)
    }

    fn decode_cell_data_to_str(
        &self,
        cell_data: String,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<String> {
        let cell_data = self.decode_type_option_cell_data(cell_data)?;
        let cell_data_pb = self.today_desc_from_timestamp(cell_data);
        Ok(cell_data_pb.date)
    }
}

impl CellDataChangeset for DateTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: AnyCellChangeset<DateCellChangeset>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.try_into_inner()?;
        let cell_data = match changeset.date_timestamp() {
            None => 0,
            Some(date_timestamp) => match (self.include_time, changeset.time) {
                (true, Some(time)) => {
                    let time = Some(time.trim().to_uppercase());
                    let native = NaiveDateTime::from_timestamp(date_timestamp, 0);

                    let utc = self.utc_date_time_from_native(native);
                    self.timestamp_from_utc_with_time(&utc, &time)?
                }
                _ => date_timestamp,
            },
        };

        Ok(cell_data.to_string())
    }
}

#[derive(Default)]
pub struct DateTypeOptionBuilder(DateTypeOptionPB);
impl_into_box_type_option_builder!(DateTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(DateTypeOptionBuilder, DateTypeOptionPB);

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

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }
    fn transform(&mut self, _field_type: &FieldType, _type_option_data: String) {
        // Do nothing
    }
}
