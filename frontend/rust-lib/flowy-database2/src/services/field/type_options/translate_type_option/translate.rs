use crate::entities::TextFilterPB;
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::type_options::util::ProtobufStr;
use crate::services::field::{
  TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionCellDataSerde,
  TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab_database::fields::translate_type_option::TranslateTypeOption;
use collab_database::rows::Cell;
use collab_database::template::translate_parse::TranslateCellData;
use flowy_error::FlowyResult;
use std::cmp::Ordering;

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
    match (cell_data.is_empty(), other_cell_data.is_empty()) {
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
