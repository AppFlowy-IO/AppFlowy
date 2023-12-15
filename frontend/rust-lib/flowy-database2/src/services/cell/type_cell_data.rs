use bytes::Bytes;
use serde::{Deserialize, Serialize};

use flowy_error::{internal_error, FlowyError, FlowyResult};

use crate::entities::FieldType;

/// TypeCellData is a generic CellData, you can parse the type_cell_data according to the field_type.
/// The `data` is encoded by JSON format. You can use `IntoCellData` to decode the opaque data to
/// concrete cell type.
/// TypeCellData -> IntoCellData<T> -> T
///
/// The `TypeCellData` is the same as the cell data that was saved to disk except it carries the
/// field_type. The field_type indicates the cell data original `FieldType`. The field_type will
/// be changed if the current Field's type switch from one to another.  
///
#[derive(Debug, Serialize, Deserialize)]
pub struct TypeCellData {
  #[serde(rename = "data")]
  pub cell_str: String,
  pub field_type: FieldType,
}

impl TypeCellData {
  pub fn from_field_type(field_type: &FieldType) -> TypeCellData {
    Self {
      cell_str: "".to_string(),
      field_type: *field_type,
    }
  }

  pub fn from_json_str(s: &str) -> FlowyResult<Self> {
    let type_cell_data: TypeCellData = serde_json::from_str(s).map_err(|err| {
      let msg = format!("Deserialize {} to type cell data failed.{}", s, err);
      FlowyError::internal().with_context(msg)
    })?;
    Ok(type_cell_data)
  }

  pub fn into_inner(self) -> String {
    self.cell_str
  }
}

impl std::convert::TryFrom<String> for TypeCellData {
  type Error = FlowyError;

  fn try_from(value: String) -> Result<Self, Self::Error> {
    TypeCellData::from_json_str(&value)
  }
}

impl ToString for TypeCellData {
  fn to_string(&self) -> String {
    self.cell_str.clone()
  }
}

impl TypeCellData {
  pub fn new(cell_str: String, field_type: FieldType) -> Self {
    TypeCellData {
      cell_str,
      field_type,
    }
  }

  pub fn to_json(&self) -> String {
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

  pub fn is_checklist(&self) -> bool {
    self.field_type == FieldType::Checklist
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
/// * Use DateCellDataPB to parse the data when the FieldType is Date.
/// * Use URLCellDataPB to parse the data when the FieldType is URL.
/// * Use String to parse the data when the FieldType is RichText, Number, or Checkbox.
/// * Check out the implementation of CellDataOperation trait for more information.
#[derive(Default, Debug)]
pub struct CellProtobufBlob(pub Bytes);

pub trait DecodedCellData {
  type Object;
  fn is_empty(&self) -> bool;
}

pub trait CellProtobufBlobParser {
  type Object: DecodedCellData;
  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object>;
}

pub trait CellStringParser {
  type Object;
  fn parser_cell_str(&self, s: &str) -> Option<Self::Object>;
}

pub trait CellBytesCustomParser {
  type Object;
  fn parse(&self, bytes: &Bytes) -> FlowyResult<Self::Object>;
}

impl CellProtobufBlob {
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

  pub fn parser<P>(&self) -> FlowyResult<P::Object>
  where
    P: CellProtobufBlobParser,
  {
    P::parser(&self.0)
  }

  pub fn custom_parser<P>(&self, parser: P) -> FlowyResult<P::Object>
  where
    P: CellBytesCustomParser,
  {
    parser.parse(&self.0)
  }

  // pub fn parse<'a, T: TryFrom<&'a [u8]>>(&'a self) -> FlowyResult<T>
  // where
  //     <T as TryFrom<&'a [u8]>>::Error: std::fmt::Debug,
  // {
  //     T::try_from(self.0.as_ref()).map_err(internal_error)
  // }
}

impl ToString for CellProtobufBlob {
  fn to_string(&self) -> String {
    match String::from_utf8(self.0.to_vec()) {
      Ok(s) => s,
      Err(e) => {
        tracing::error!("DecodedCellData to string failed: {:?}", e);
        "".to_string()
      },
    }
  }
}

impl std::ops::Deref for CellProtobufBlob {
  type Target = Bytes;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}
