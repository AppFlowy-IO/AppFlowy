use crate::entities::{FieldType, TextFilterPB, URLCellDataPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  TypeOption, TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionCellDataSerde,
  TypeOptionTransform, URLCellData,
};
use crate::services::sort::SortCondition;
use async_trait::async_trait;
use collab_database::database::Database;
use collab_database::fields::url_type_option::URLTypeOption;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::Cell;
use flowy_error::FlowyResult;

use std::cmp::Ordering;
use tracing::trace;

impl TypeOption for URLTypeOption {
  type CellData = URLCellData;
  type CellChangeset = URLCellChangeset;
  type CellProtobufType = URLCellDataPB;
  type CellFilter = TextFilterPB;
}

#[async_trait]
impl TypeOptionTransform for URLTypeOption {
  async fn transform_type_option(
    &mut self,
    view_id: &str,
    field_id: &str,
    old_type_option_field_type: FieldType,
    _old_type_option_data: TypeOptionData,
    _new_type_option_field_type: FieldType,
    database: &mut Database,
  ) {
    match old_type_option_field_type {
      FieldType::RichText => {
        let rows = database
          .get_cells_for_field(view_id, field_id)
          .await
          .into_iter()
          .filter_map(|row| row.cell.map(|cell| (row.row_id, cell)))
          .collect::<Vec<_>>();

        trace!(
          "Transforming RichText to URLTypeOption, updating {} row's cell content",
          rows.len()
        );
        for (row_id, cell_data) in rows {
          database
            .update_row(row_id, |row| {
              row.update_cells(|cell| {
                cell.insert(field_id, Self::CellData::from(&cell_data));
              });
            })
            .await;
        }
      },
      _ => {
        // Do nothing
      },
    }
  }
}

impl TypeOptionCellDataSerde for URLTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    cell_data.into()
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(URLCellData::from(cell))
  }
}

impl CellDataDecoder for URLTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }
  fn decode_cell_with_transform(
    &self,
    cell: &Cell,
    from_field_type: FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    match from_field_type {
      FieldType::RichText => Some(Self::CellData::from(cell)),
      _ => None,
    }
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    cell_data.data
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}

pub type URLCellChangeset = String;

impl CellDataChangeset for URLTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let url_cell_data = URLCellData { data: changeset };
    Ok((url_cell_data.clone().into(), url_cell_data))
  }
}

impl TypeOptionCellDataFilter for URLTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data)
  }
}

impl TypeOptionCellDataCompare for URLTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    let is_left_empty = cell_data.data.is_empty();
    let is_right_empty = other_cell_data.data.is_empty();
    match (is_left_empty, is_right_empty) {
      (true, true) => Ordering::Equal,
      (true, false) => Ordering::Greater,
      (false, true) => Ordering::Less,
      (false, false) => {
        let order = cell_data.data.cmp(&other_cell_data.data);
        sort_condition.evaluate_order(order)
      },
    }
  }
}
