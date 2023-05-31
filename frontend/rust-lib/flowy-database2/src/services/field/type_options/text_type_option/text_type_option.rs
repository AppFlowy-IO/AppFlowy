use std::cmp::Ordering;

use bytes::Bytes;
use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::{new_cell_builder, Cell};
use serde::{Deserialize, Serialize};

use flowy_error::{FlowyError, FlowyResult};

use crate::entities::{FieldType, TextFilterPB};
use crate::services::cell::{
  stringify_cell_data, CellDataChangeset, CellDataDecoder, CellProtobufBlobParser, DecodedCellData,
  FromCellString,
};
use crate::services::field::type_options::util::ProtobufStr;
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionTransform, CELL_DATA,
};

/// For the moment, the `RichTextTypeOptionPB` is empty. The `data` property is not
/// used yet.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RichTextTypeOption {
  #[serde(default)]
  pub inner: String,
}

impl TypeOption for RichTextTypeOption {
  type CellData = StrCellData;
  type CellChangeset = String;
  type CellProtobufType = ProtobufStr;
  type CellFilter = TextFilterPB;
}

impl From<TypeOptionData> for RichTextTypeOption {
  fn from(data: TypeOptionData) -> Self {
    let s = data.get_str_value(CELL_DATA).unwrap_or_default();
    Self { inner: s }
  }
}

impl From<RichTextTypeOption> for TypeOptionData {
  fn from(data: RichTextTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_str_value(CELL_DATA, data.inner)
      .build()
  }
}

impl TypeOptionTransform for RichTextTypeOption {
  fn transformable(&self) -> bool {
    true
  }

  fn transform_type_option(
    &mut self,
    _old_type_option_field_type: FieldType,
    _old_type_option_data: TypeOptionData,
  ) {
  }

  fn transform_type_option_cell(
    &self,
    cell: &Cell,
    transformed_field_type: &FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    if transformed_field_type.is_date()
      || transformed_field_type.is_single_select()
      || transformed_field_type.is_multi_select()
      || transformed_field_type.is_number()
      || transformed_field_type.is_url()
    {
      Some(StrCellData::from(stringify_cell_data(
        cell,
        transformed_field_type,
        transformed_field_type,
        _field,
      )))
    } else {
      Some(StrCellData::from(cell))
    }
  }
}

impl TypeOptionCellData for RichTextTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    ProtobufStr::from(cell_data.0)
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(StrCellData::from(cell))
  }
}

impl CellDataDecoder for RichTextTypeOption {
  fn decode_cell(
    &self,
    cell: &Cell,
    _decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(StrCellData::from(cell))
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.to_string()
  }

  fn stringify_cell(&self, cell: &Cell) -> String {
    Self::CellData::from(cell).to_string()
  }
}

impl CellDataChangeset for RichTextTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    if changeset.len() > 10000 {
      Err(FlowyError::text_too_long().context("The len of the text should not be more than 10000"))
    } else {
      let text_cell_data = StrCellData(changeset);
      Ok((text_cell_data.clone().into(), text_cell_data))
    }
  }
}

impl TypeOptionCellDataFilter for RichTextTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_text() {
      return false;
    }

    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for RichTextTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    cell_data.0.cmp(&other_cell_data.0)
  }
}

#[derive(Clone)]
pub struct TextCellData(pub String);
impl AsRef<str> for TextCellData {
  fn as_ref(&self) -> &str {
    &self.0
  }
}

impl std::ops::Deref for TextCellData {
  type Target = String;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl FromCellString for TextCellData {
  fn from_cell_str(s: &str) -> FlowyResult<Self>
  where
    Self: Sized,
  {
    Ok(TextCellData(s.to_owned()))
  }
}

impl ToString for TextCellData {
  fn to_string(&self) -> String {
    self.0.clone()
  }
}

impl DecodedCellData for TextCellData {
  type Object = TextCellData;

  fn is_empty(&self) -> bool {
    self.0.is_empty()
  }
}

pub struct TextCellDataParser();
impl CellProtobufBlobParser for TextCellDataParser {
  type Object = TextCellData;
  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    match String::from_utf8(bytes.to_vec()) {
      Ok(s) => Ok(TextCellData(s)),
      Err(_) => Ok(TextCellData("".to_owned())),
    }
  }
}

#[derive(Default, Debug, Clone)]
pub struct StrCellData(pub String);
impl std::ops::Deref for StrCellData {
  type Target = String;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl From<&Cell> for StrCellData {
  fn from(cell: &Cell) -> Self {
    Self(cell.get_str_value("data").unwrap_or_default())
  }
}

impl From<StrCellData> for Cell {
  fn from(data: StrCellData) -> Self {
    new_cell_builder(FieldType::RichText)
      .insert_str_value("data", data.0)
      .build()
  }
}

impl std::ops::DerefMut for StrCellData {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

impl FromCellString for StrCellData {
  fn from_cell_str(s: &str) -> FlowyResult<Self> {
    Ok(Self(s.to_owned()))
  }
}

impl std::convert::From<String> for StrCellData {
  fn from(s: String) -> Self {
    Self(s)
  }
}

impl ToString for StrCellData {
  fn to_string(&self) -> String {
    self.0.clone()
  }
}

impl std::convert::From<StrCellData> for String {
  fn from(value: StrCellData) -> Self {
    value.0
  }
}

impl std::convert::From<&str> for StrCellData {
  fn from(s: &str) -> Self {
    Self(s.to_owned())
  }
}

impl AsRef<str> for StrCellData {
  fn as_ref(&self) -> &str {
    self.0.as_str()
  }
}
