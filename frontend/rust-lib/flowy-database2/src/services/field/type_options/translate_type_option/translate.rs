use crate::entities::TextFilterPB;
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::type_options::translate_type_option::translate_entities::TranslateCellData;
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
use std::cmp::Ordering;

#[derive(Debug, Clone)]
pub struct TranslateTypeOption {
  pub auto_fill: bool,
  pub language: String,
}

impl Default for TranslateTypeOption {
  fn default() -> Self {
    Self {
      auto_fill: false,
      language: "english".to_string(),
    }
  }
}

impl From<TypeOptionData> for TranslateTypeOption {
  fn from(value: TypeOptionData) -> Self {
    let auto_fill = value.get_bool_value("auto_fill").unwrap_or_default();
    let language = value.get_str_value("language").unwrap_or_default();
    Self {
      auto_fill,
      language,
    }
  }
}

impl From<TranslateTypeOption> for TypeOptionData {
  fn from(value: TranslateTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_bool_value("auto_fill", value.auto_fill)
      .insert_str_value("language", value.language)
      .build()
  }
}

impl TypeOption for TranslateTypeOption {
  type CellData = TranslateCellData;
  type CellChangeset = String;
  type CellProtobufType = ProtobufStr;
  type CellFilter = TextFilterPB;
}

impl CellDataChangeset for TranslateTypeOption {
  fn apply_changeset(
    &self,
    changeset: String,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, TranslateCellData)> {
    let cell_data = TranslateCellData(changeset);
    Ok((cell_data.clone().into(), cell_data))
  }
}

impl TypeOptionCellDataFilter for TranslateTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for TranslateTypeOption {
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

impl CellDataDecoder for TranslateTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<TranslateCellData> {
    Ok(TranslateCellData::from(cell))
  }

  fn stringify_cell_data(&self, cell_data: TranslateCellData) -> String {
    cell_data.to_string()
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}
impl TypeOptionTransform for TranslateTypeOption {}

impl TypeOptionCellDataSerde for TranslateTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    ProtobufStr::from(cell_data.0)
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(TranslateCellData::from(cell))
  }
}
