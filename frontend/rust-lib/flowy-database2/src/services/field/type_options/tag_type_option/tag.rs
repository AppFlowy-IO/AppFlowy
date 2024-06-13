use crate::entities::TextFilterPB;
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::type_options::tag_type_option::tag_entities::TagCellData;
use crate::services::field::type_options::util::ProtobufStr;
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionCellDataSerde, TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab::core::any_map::{AnyMap, AnyMapExtension};
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

#[derive(Debug, Clone, Default)]
pub struct TagTypeOption {
  pub tags: Vec<TagOption>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct TagOption {
  pub color: String,
  pub text: String,
}

impl From<AnyMap> for TagOption {
  fn from(value: AnyMap) -> Self {
    let color = value.get_string("color").unwrap_or_default();
    let text = value.get_string("text").unwrap_or_default();
    Self { color, text }
  }
}

impl From<TagOption> for AnyMap {
  fn from(value: TagOption) -> Self {
    let mut map = AnyMap::new();
    map.insert_string("color", value.color);
    map.insert_string("text", value.text);
    map
  }
}
impl From<TypeOptionData> for TagTypeOption {
  fn from(value: TypeOptionData) -> Self {
    let tags = value.get_array("tags");
    Self { tags }
  }
}

impl From<TagTypeOption> for TypeOptionData {
  fn from(value: TagTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_maps("tags", value.tags)
      .build()
  }
}

impl TypeOption for TagTypeOption {
  type CellData = TagCellData;
  type CellChangeset = String;
  type CellProtobufType = ProtobufStr;
  type CellFilter = TextFilterPB;
}

impl CellDataChangeset for TagTypeOption {
  fn apply_changeset(
    &self,
    changeset: String,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, TagCellData)> {
    let cell_data = TagCellData(changeset);
    Ok((cell_data.clone().into(), cell_data))
  }
}

impl TypeOptionCellDataFilter for TagTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for TagTypeOption {
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

impl CellDataDecoder for TagTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<TagCellData> {
    Ok(TagCellData::from(cell))
  }

  fn stringify_cell_data(&self, cell_data: TagCellData) -> String {
    cell_data.to_string()
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}
impl TypeOptionTransform for TagTypeOption {}

impl TypeOptionCellDataSerde for TagTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    ProtobufStr::from(cell_data.0)
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(TagCellData::from(cell))
  }
}
