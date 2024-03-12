use std::cmp::Ordering;

use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};

use crate::entities::{FieldType, RelationCellDataPB, RelationFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionCellDataSerde, TypeOptionTransform,
};
use crate::services::sort::SortCondition;

use super::{RelationCellChangeset, RelationCellData};

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RelationTypeOption {
  pub database_id: String,
}

impl From<TypeOptionData> for RelationTypeOption {
  fn from(value: TypeOptionData) -> Self {
    let database_id = value.get_str_value("database_id").unwrap_or_default();
    Self { database_id }
  }
}

impl From<RelationTypeOption> for TypeOptionData {
  fn from(value: RelationTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_str_value("database_id", value.database_id)
      .build()
  }
}

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

      return Ok(((&cell_data).into(), cell_data));
    }

    let cell_data: RelationCellData = cell.unwrap().as_ref().into();
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

    Ok(((&cell_data).into(), cell_data))
  }
}

impl CellDataDecoder for RelationTypeOption {
  fn decode_cell(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<RelationCellData> {
    if !decoded_field_type.is_relation() {
      return Ok(Default::default());
    }

    Ok(cell.into())
  }

  fn stringify_cell_data(&self, cell_data: RelationCellData) -> String {
    cell_data.to_string()
  }

  fn stringify_cell(&self, cell: &Cell) -> String {
    let cell_data = RelationCellData::from(cell);
    cell_data.to_string()
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
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

impl TypeOptionTransform for RelationTypeOption {
  fn transformable(&self) -> bool {
    false
  }

  fn transform_type_option(
    &mut self,
    _old_type_option_field_type: FieldType,
    _old_type_option_data: TypeOptionData,
  ) {
  }

  fn transform_type_option_cell(
    &self,
    _cell: &Cell,
    _transformed_field_type: &FieldType,
    _field: &Field,
  ) -> Option<RelationCellData> {
    None
  }
}

impl TypeOptionCellDataSerde for RelationTypeOption {
  fn protobuf_encode(&self, cell_data: RelationCellData) -> RelationCellDataPB {
    cell_data.into()
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<RelationCellData> {
    Ok(cell.into())
  }
}
