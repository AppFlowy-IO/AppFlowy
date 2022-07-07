use crate::entities::FieldType;
use crate::services::field::*;
use bytes::Bytes;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, FieldTypeRevision};
use serde::{Deserialize, Serialize};
use std::fmt::Formatter;
use std::str::FromStr;

pub trait CellFilterOperation<T> {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &T) -> FlowyResult<bool>;
}

pub trait CellDataOperation<D> {
    fn decode_cell_data<T>(
        &self,
        cell_data: T,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<D>;

    fn apply_changeset<C: Into<CellContentChangeset>>(
        &self,
        changeset: C,
        cell_rev: Option<CellRevision>,
    ) -> FlowyResult<String>;
}

#[derive(Debug)]
pub struct CellContentChangeset(pub String);

impl std::fmt::Display for CellContentChangeset {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", &self.0)
    }
}

impl<T: AsRef<str>> std::convert::From<T> for CellContentChangeset {
    fn from(s: T) -> Self {
        let s = s.as_ref().to_owned();
        CellContentChangeset(s)
    }
}

impl std::ops::Deref for CellContentChangeset {
    type Target = str;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AnyCellData {
    pub cell_data: String,
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

impl std::convert::TryFrom<&Option<CellRevision>> for AnyCellData {
    type Error = FlowyError;

    fn try_from(value: &Option<CellRevision>) -> Result<Self, Self::Error> {
        match value {
            None => Err(FlowyError::invalid_data().context("Expected CellRevision, but receive None")),
            Some(cell_rev) => AnyCellData::try_from(cell_rev),
        }
    }
}

impl std::convert::TryFrom<Option<CellRevision>> for AnyCellData {
    type Error = FlowyError;

    fn try_from(value: Option<CellRevision>) -> Result<Self, Self::Error> {
        Self::try_from(&value)
    }
}

impl AnyCellData {
    pub fn new(content: String, field_type: FieldType) -> Self {
        AnyCellData {
            cell_data: content,
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

/// The changeset will be deserialized into specific data base on the FieldType.
/// For example, it's String on FieldType::RichText, and SelectOptionChangeset on FieldType::SingleSelect
pub fn apply_cell_data_changeset<C: Into<CellContentChangeset>, T: AsRef<FieldRevision>>(
    changeset: C,
    cell_rev: Option<CellRevision>,
    field_rev: T,
) -> Result<String, FlowyError> {
    let field_rev = field_rev.as_ref();
    let field_type = field_rev.field_type_rev.into();
    let s = match field_type {
        FieldType::RichText => RichTextTypeOption::from(field_rev).apply_changeset(changeset, cell_rev),
        FieldType::Number => NumberTypeOption::from(field_rev).apply_changeset(changeset, cell_rev),
        FieldType::DateTime => DateTypeOption::from(field_rev).apply_changeset(changeset, cell_rev),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field_rev).apply_changeset(changeset, cell_rev),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field_rev).apply_changeset(changeset, cell_rev),
        FieldType::Checkbox => CheckboxTypeOption::from(field_rev).apply_changeset(changeset, cell_rev),
        FieldType::URL => URLTypeOption::from(field_rev).apply_changeset(changeset, cell_rev),
    }?;

    Ok(AnyCellData::new(s, field_type).json())
}

pub fn decode_any_cell_data<T: TryInto<AnyCellData>>(data: T, field_rev: &FieldRevision) -> DecodedCellData {
    if let Ok(any_cell_data) = data.try_into() {
        let AnyCellData { cell_data, field_type } = any_cell_data;
        let to_field_type = field_rev.field_type_rev.into();
        match try_decode_cell_data(cell_data, field_rev, &field_type, &to_field_type) {
            Ok(cell_data) => cell_data,
            Err(e) => {
                tracing::error!("Decode cell data failed, {:?}", e);
                DecodedCellData::default()
            }
        }
    } else {
        tracing::error!("Decode type option data failed");
        DecodedCellData::default()
    }
}

pub fn try_decode_cell_data(
    cell_data: String,
    field_rev: &FieldRevision,
    s_field_type: &FieldType,
    t_field_type: &FieldType,
) -> FlowyResult<DecodedCellData> {
    let get_cell_data = || {
        let field_type: FieldTypeRevision = t_field_type.into();
        let data = match t_field_type {
            FieldType::RichText => field_rev
                .get_type_option_entry::<RichTextTypeOption>(field_type)?
                .decode_cell_data(cell_data, s_field_type, field_rev),
            FieldType::Number => field_rev
                .get_type_option_entry::<NumberTypeOption>(field_type)?
                .decode_cell_data(cell_data, s_field_type, field_rev),
            FieldType::DateTime => field_rev
                .get_type_option_entry::<DateTypeOption>(field_type)?
                .decode_cell_data(cell_data, s_field_type, field_rev),
            FieldType::SingleSelect => field_rev
                .get_type_option_entry::<SingleSelectTypeOption>(field_type)?
                .decode_cell_data(cell_data, s_field_type, field_rev),
            FieldType::MultiSelect => field_rev
                .get_type_option_entry::<MultiSelectTypeOption>(field_type)?
                .decode_cell_data(cell_data, s_field_type, field_rev),
            FieldType::Checkbox => field_rev
                .get_type_option_entry::<CheckboxTypeOption>(field_type)?
                .decode_cell_data(cell_data, s_field_type, field_rev),
            FieldType::URL => field_rev
                .get_type_option_entry::<URLTypeOption>(field_type)?
                .decode_cell_data(cell_data, s_field_type, field_rev),
        };
        Some(data)
    };

    match get_cell_data() {
        Some(Ok(data)) => Ok(data),
        Some(Err(err)) => {
            tracing::error!("{:?}", err);
            Ok(DecodedCellData::default())
        }
        None => Ok(DecodedCellData::default()),
    }
}

pub(crate) struct EncodedCellData<T>(pub Option<T>);

impl<T> EncodedCellData<T> {
    pub fn try_into_inner(self) -> FlowyResult<T> {
        match self.0 {
            None => Err(ErrorCode::InvalidData.into()),
            Some(data) => Ok(data),
        }
    }
}

impl<T> std::convert::From<String> for EncodedCellData<T>
where
    T: FromStr<Err = FlowyError>,
{
    fn from(s: String) -> Self {
        match T::from_str(&s) {
            Ok(inner) => EncodedCellData(Some(inner)),
            Err(e) => {
                tracing::error!("Deserialize Cell Data failed: {}", e);
                EncodedCellData(None)
            }
        }
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
pub struct DecodedCellData {
    pub data: Vec<u8>,
}

impl DecodedCellData {
    pub fn new<T: AsRef<[u8]>>(data: T) -> Self {
        Self {
            data: data.as_ref().to_vec(),
        }
    }

    pub fn try_from_bytes<T: TryInto<Bytes>>(bytes: T) -> FlowyResult<Self>
    where
        <T as TryInto<Bytes>>::Error: std::fmt::Debug,
    {
        let bytes = bytes.try_into().map_err(internal_error)?;
        Ok(Self { data: bytes.to_vec() })
    }

    pub fn parse<'a, T: TryFrom<&'a [u8]>>(&'a self) -> FlowyResult<T>
    where
        <T as TryFrom<&'a [u8]>>::Error: std::fmt::Debug,
    {
        T::try_from(self.data.as_ref()).map_err(internal_error)
    }
}

impl ToString for DecodedCellData {
    fn to_string(&self) -> String {
        match String::from_utf8(self.data.clone()) {
            Ok(s) => s,
            Err(e) => {
                tracing::error!("DecodedCellData to string failed: {:?}", e);
                "".to_string()
            }
        }
    }
}
