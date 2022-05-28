use crate::services::field::*;
use bytes::Bytes;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{CellMeta, FieldMeta, FieldType};
use serde::{Deserialize, Serialize};
use std::fmt::Formatter;
use std::str::FromStr;

pub trait CellDataOperation<D, CO: ToString> {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<D>;

    //
    fn apply_changeset<C: Into<CellContentChangeset>>(
        &self,
        changeset: C,
        cell_meta: Option<CellMeta>,
    ) -> FlowyResult<CO>;
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
pub struct TypeOptionCellData {
    pub data: String,
    pub field_type: FieldType,
}

impl TypeOptionCellData {
    pub fn split(self) -> (String, FieldType) {
        (self.data, self.field_type)
    }
}

impl std::str::FromStr for TypeOptionCellData {
    type Err = FlowyError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let type_option_cell_data: TypeOptionCellData = serde_json::from_str(s)?;
        Ok(type_option_cell_data)
    }
}

impl std::convert::TryInto<TypeOptionCellData> for String {
    type Error = FlowyError;

    fn try_into(self) -> Result<TypeOptionCellData, Self::Error> {
        TypeOptionCellData::from_str(&self)
    }
}

impl TypeOptionCellData {
    pub fn new<T: ToString>(data: T, field_type: FieldType) -> Self {
        TypeOptionCellData {
            data: data.to_string(),
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

    pub fn is_select_option(&self) -> bool {
        self.field_type == FieldType::MultiSelect || self.field_type == FieldType::SingleSelect
    }
}

/// The changeset will be deserialized into specific data base on the FieldType.
/// For example, it's String on FieldType::RichText, and SelectOptionChangeset on FieldType::SingleSelect
pub fn apply_cell_data_changeset<T: Into<CellContentChangeset>>(
    changeset: T,
    cell_meta: Option<CellMeta>,
    field_meta: &FieldMeta,
) -> Result<String, FlowyError> {
    let s = match field_meta.field_type {
        FieldType::RichText => RichTextTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::Number => NumberTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::DateTime => DateTypeOption::from(field_meta)
            .apply_changeset(changeset, cell_meta)
            .map(|data| data.to_string()),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::Checkbox => CheckboxTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
        FieldType::URL => URLTypeOption::from(field_meta).apply_changeset(changeset, cell_meta),
    }?;

    Ok(TypeOptionCellData::new(s, field_meta.field_type.clone()).json())
}

pub fn decode_cell_data_from_type_option_cell_data<T: TryInto<TypeOptionCellData>>(
    data: T,
    field_meta: &FieldMeta,
    field_type: &FieldType,
) -> DecodedCellData {
    if let Ok(type_option_cell_data) = data.try_into() {
        let (encoded_data, s_field_type) = type_option_cell_data.split();
        match decode_cell_data(encoded_data, &s_field_type, field_type, field_meta) {
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

pub fn decode_cell_data<T: Into<String>>(
    encoded_data: T,
    s_field_type: &FieldType,
    t_field_type: &FieldType,
    field_meta: &FieldMeta,
) -> FlowyResult<DecodedCellData> {
    let encoded_data = encoded_data.into();
    tracing::info!("😁{:?}", field_meta.type_options);
    let get_cell_data = || {
        let data = match t_field_type {
            FieldType::RichText => field_meta
                .get_type_option_entry::<RichTextTypeOption>(t_field_type)?
                .decode_cell_data(encoded_data, s_field_type, field_meta),
            FieldType::Number => field_meta
                .get_type_option_entry::<NumberTypeOption>(t_field_type)?
                .decode_cell_data(encoded_data, s_field_type, field_meta),
            FieldType::DateTime => field_meta
                .get_type_option_entry::<DateTypeOption>(t_field_type)?
                .decode_cell_data(encoded_data, s_field_type, field_meta),
            FieldType::SingleSelect => field_meta
                .get_type_option_entry::<SingleSelectTypeOption>(t_field_type)?
                .decode_cell_data(encoded_data, s_field_type, field_meta),
            FieldType::MultiSelect => field_meta
                .get_type_option_entry::<MultiSelectTypeOption>(t_field_type)?
                .decode_cell_data(encoded_data, s_field_type, field_meta),
            FieldType::Checkbox => field_meta
                .get_type_option_entry::<CheckboxTypeOption>(t_field_type)?
                .decode_cell_data(encoded_data, s_field_type, field_meta),
            FieldType::URL => field_meta
                .get_type_option_entry::<URLTypeOption>(t_field_type)?
                .decode_cell_data(encoded_data, s_field_type, field_meta),
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
