use crate::entities::FieldType;
use bytes::Bytes;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::CellRevision;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
/// AnyCellData is a generic CellData, you can parse the cell_data according to the field_type.
/// When the type of field is changed, it's different from the field_type of AnyCellData.
/// So it will return an empty data. You could check the CellDataOperation trait for more information.
#[derive(Debug, Serialize, Deserialize)]
pub struct AnyCellData {
    pub data: String,
    pub field_type: FieldType,
}

impl std::str::FromStr for AnyCellData {
    type Err = FlowyError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let type_option_cell_data: AnyCellData = serde_json::from_str(s)?;
        Ok(type_option_cell_data)
    }
}

impl std::convert::TryInto<AnyCellData> for String {
    type Error = FlowyError;

    fn try_into(self) -> Result<AnyCellData, Self::Error> {
        AnyCellData::from_str(&self)
    }
}

impl std::convert::TryFrom<&CellRevision> for AnyCellData {
    type Error = FlowyError;

    fn try_from(value: &CellRevision) -> Result<Self, Self::Error> {
        Self::from_str(&value.data)
    }
}

impl std::convert::TryFrom<CellRevision> for AnyCellData {
    type Error = FlowyError;

    fn try_from(value: CellRevision) -> Result<Self, Self::Error> {
        Self::try_from(&value)
    }
}

impl AnyCellData {
    pub fn new(content: String, field_type: FieldType) -> Self {
        AnyCellData {
            data: content,
            field_type,
        }
    }

    pub fn json(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_owned())
    }

    pub fn is_number(&self) -> bool {
        self.field_type == FieldType::Number
    }

    pub fn is_text(&self) -> bool {
        self.field_type == FieldType::RichText
    }

    pub fn is_checkbox(&self) -> bool {
        self.field_type == FieldType::Checkbox
    }

    pub fn is_date(&self) -> bool {
        self.field_type == FieldType::DateTime
    }

    pub fn is_single_select(&self) -> bool {
        self.field_type == FieldType::SingleSelect
    }

    pub fn is_multi_select(&self) -> bool {
        self.field_type == FieldType::MultiSelect
    }

    pub fn is_url(&self) -> bool {
        self.field_type == FieldType::URL
    }

    pub fn is_select_option(&self) -> bool {
        self.field_type == FieldType::MultiSelect || self.field_type == FieldType::SingleSelect
    }
}

/// The data is encoded by protobuf or utf8. You should choose the corresponding decode struct to parse it.
///
/// For example:
///
/// * Use DateCellData to parse the data when the FieldType is Date.
/// * Use URLCellData to parse the data when the FieldType is URL.
/// * Use String to parse the data when the FieldType is RichText, Number, or Checkbox.
/// * Check out the implementation of CellDataOperation trait for more information.
#[derive(Default)]
pub struct CellBytes(pub Bytes);

impl CellBytes {
    pub fn new<T: AsRef<[u8]>>(data: T) -> Self {
        let bytes = Bytes::from(data.as_ref().to_vec());
        Self(bytes)
    }

    pub fn from<T: TryInto<Bytes>>(bytes: T) -> FlowyResult<Self>
    where
        <T as TryInto<Bytes>>::Error: std::fmt::Debug,
    {
        let bytes = bytes.try_into().map_err(internal_error)?;
        Ok(Self(bytes))
    }

    pub fn parse<'a, T: TryFrom<&'a [u8]>>(&'a self) -> FlowyResult<T>
    where
        <T as TryFrom<&'a [u8]>>::Error: std::fmt::Debug,
    {
        T::try_from(self.0.as_ref()).map_err(internal_error)
    }
}

impl ToString for CellBytes {
    fn to_string(&self) -> String {
        match String::from_utf8(self.0.to_vec()) {
            Ok(s) => s,
            Err(e) => {
                tracing::error!("DecodedCellData to string failed: {:?}", e);
                "".to_string()
            }
        }
    }
}

impl std::ops::Deref for CellBytes {
    type Target = Bytes;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
