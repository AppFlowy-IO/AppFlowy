use std::cmp::Ordering;

use collab_database::fields::relation_type_option::RelationTypeOption;

use collab_database::rows::Cell;
use collab_database::template::relation_parse::RelationCellData;
use collab_database::template::util::ToCellString;
use flowy_error::FlowyResult;

use crate::entities::{RelationCellDataPB, RelationFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, CellDataProtobufEncoder, TypeOption, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionTransform,
};
use crate::services::sort::SortCondition;

use super::RelationCellChangeset;

impl TypeOption for RelationTypeOption {
  type CellData = RelationCellData;
  type CellChangeset = RelationCellChangeset;
  type CellProtobufType = RelationCellDataPB;
  type CellFilter = RelationFilterPB;
}

impl CellDataChangeset for RelationTypeOption {
  fn apply_changeset(
    &self,
    changeset: RelationCellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, RelationCellData)> {
    if cell.is_none() {
      let cell_data = RelationCellData {
        row_ids: changeset.inserted_row_ids,
      };
      return Ok(((cell_data.clone()).into(), cell_data));
    }

    let cell_data: RelationCellData = cell.as_ref().unwrap().into();
    let mut row_ids = cell_data.row_ids.clone();
    for inserted in changeset.inserted_row_ids.iter() {
      if !row_ids.iter().any(|row_id| row_id == inserted) {
        row_ids.push(inserted.clone())
      }
    }
    for removed_id in changeset.removed_row_ids.iter() {
      if let Some(index) = row_ids.iter().position(|row_id| row_id == removed_id) {
        row_ids.remove(index);
      }
    }

    let cell_data = RelationCellData { row_ids };

    Ok(((cell_data.clone()).into(), cell_data))
  }
}

impl CellDataDecoder for RelationTypeOption {
  fn stringify_cell_data(&self, cell_data: RelationCellData) -> String {
    cell_data.to_cell_string()
  }
}

impl TypeOptionCellDataCompare for RelationTypeOption {
  fn apply_cmp(
    &self,
    _cell_data: &RelationCellData,
    _other_cell_data: &RelationCellData,
    _sort_condition: SortCondition,
  ) -> Ordering {
    default_order()
  }
}

impl TypeOptionCellDataFilter for RelationTypeOption {
  fn apply_filter(&self, _filter: &RelationFilterPB, _cell_data: &RelationCellData) -> bool {
    true
  }
}

impl TypeOptionTransform for RelationTypeOption {}

impl CellDataProtobufEncoder for RelationTypeOption {
  fn protobuf_encode(&self, cell_data: RelationCellData) -> RelationCellDataPB {
    cell_data.into()
  }
}
