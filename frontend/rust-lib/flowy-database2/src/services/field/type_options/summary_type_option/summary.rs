use crate::entities::TextFilterPB;
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::summary_type_option::summary_entities::SummaryCellData;
use crate::services::field::type_options::util::ProtobufStr;
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionCellDataSerde, TypeOptionTransform,
};
use crate::services::sort::SortCondition;
use collab::util::AnyMapExt;
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use std::cmp::Ordering;

#[derive(Default, Debug, Clone)]
pub struct SummarizationTypeOption {
  pub auto_fill: bool,
}

impl From<TypeOptionData> for SummarizationTypeOption {
  fn from(value: TypeOptionData) -> Self {
    let auto_fill: bool = value.get_as("auto_fill").unwrap_or_default();
    Self { auto_fill }
  }
}

impl From<SummarizationTypeOption> for TypeOptionData {
  fn from(value: SummarizationTypeOption) -> Self {
    TypeOptionDataBuilder::from([("auto_fill".into(), value.auto_fill.into())])
  }
}

impl TypeOption for SummarizationTypeOption {
  type CellData = SummaryCellData;
  type CellChangeset = String;
  type CellProtobufType = ProtobufStr;
  type CellFilter = TextFilterPB;
}

impl CellDataChangeset for SummarizationTypeOption {
  fn apply_changeset(
    &self,
    changeset: String,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, SummaryCellData)> {
    let cell_data = SummaryCellData(changeset);
    Ok((cell_data.clone().into(), cell_data))
  }
}

impl TypeOptionCellDataFilter for SummarizationTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for SummarizationTypeOption {
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

impl CellDataDecoder for SummarizationTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<SummaryCellData> {
    Ok(SummaryCellData::from(cell))
  }

  fn stringify_cell_data(&self, cell_data: SummaryCellData) -> String {
    cell_data.to_string()
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}
impl TypeOptionTransform for SummarizationTypeOption {}

impl TypeOptionCellDataSerde for SummarizationTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    ProtobufStr::from(cell_data.0)
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(SummaryCellData::from(cell))
  }
}
