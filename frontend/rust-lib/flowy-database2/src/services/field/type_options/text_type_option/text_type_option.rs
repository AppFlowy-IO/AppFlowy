use std::cmp::Ordering;

use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::{new_cell_builder, Cell};
use serde::{Deserialize, Serialize};

use flowy_error::{FlowyError, FlowyResult};

use crate::entities::{FieldType, TextFilterPB};
use crate::services::cell::{stringify_cell, CellDataChangeset, CellDataDecoder};
use crate::services::field::type_options::util::ProtobufStr;
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionCellDataSerde, TypeOptionTransform, CELL_DATA,
};
use crate::services::sort::SortCondition;

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

impl TypeOptionTransform for RichTextTypeOption {}

impl TypeOptionCellDataSerde for RichTextTypeOption {
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
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(StrCellData::from(cell))
  }

  fn decode_cell_with_transform(
    &self,
    cell: &Cell,
    from_field_type: FieldType,
    field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    match from_field_type {
      FieldType::RichText
      | FieldType::Number
      | FieldType::DateTime
      | FieldType::SingleSelect
      | FieldType::MultiSelect
      | FieldType::Checkbox
      | FieldType::URL => Some(StrCellData::from(stringify_cell(cell, field))),
      FieldType::Checklist
      | FieldType::LastEditedTime
      | FieldType::CreatedTime
      | FieldType::Relation => None,
    }
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.to_string()
  }

  fn numeric_cell(&self, cell: &Cell) -> Option<f64> {
    StrCellData::from(cell).0.parse::<f64>().ok()
  }
}

impl CellDataChangeset for RichTextTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    if changeset.len() > 10000 {
      Err(
        FlowyError::text_too_long()
          .with_context("The len of the text should not be more than 10000"),
      )
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
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for RichTextTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    match (cell_data.is_cell_empty(), other_cell_data.is_cell_empty()) {
      (true, true) => Ordering::Equal,
      (true, false) => Ordering::Greater,
      (false, true) => Ordering::Less,
      (false, false) => {
        let order = cell_data.0.cmp(&other_cell_data.0);
        sort_condition.evaluate_order(order)
      },
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

impl TypeOptionCellData for StrCellData {
  fn is_cell_empty(&self) -> bool {
    self.0.is_empty()
  }
}

impl From<&Cell> for StrCellData {
  fn from(cell: &Cell) -> Self {
    Self(cell.get_str_value(CELL_DATA).unwrap_or_default())
  }
}

impl From<StrCellData> for Cell {
  fn from(data: StrCellData) -> Self {
    new_cell_builder(FieldType::RichText)
      .insert_str_value(CELL_DATA, data.0)
      .build()
  }
}

impl std::ops::DerefMut for StrCellData {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
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
