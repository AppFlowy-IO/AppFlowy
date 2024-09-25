use async_trait::async_trait;

use collab::util::AnyMapExt;
use collab_database::database::Database;
use collab_database::fields::number_type_option::{
  NumberCellFormat, NumberFormat, NumberTypeOption,
};
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{new_cell_builder, Cell};
use fancy_regex::Regex;
use flowy_error::FlowyResult;
use lazy_static::lazy_static;

use std::cmp::Ordering;
use std::default::Default;

use tracing::info;

use crate::entities::{FieldType, NumberFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::type_options::util::ProtobufStr;
use crate::services::field::{
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionCellDataSerde, TypeOptionTransform, CELL_DATA,
};
use crate::services::sort::SortCondition;

#[derive(Clone, Debug, Default)]
pub struct NumberCellData(pub String);

impl TypeOptionCellData for NumberCellData {
  fn is_cell_empty(&self) -> bool {
    self.0.is_empty()
  }
}

impl AsRef<str> for NumberCellData {
  fn as_ref(&self) -> &str {
    &self.0
  }
}

impl From<&Cell> for NumberCellData {
  fn from(cell: &Cell) -> Self {
    Self(cell.get_as(CELL_DATA).unwrap_or_default())
  }
}

impl From<NumberCellData> for Cell {
  fn from(data: NumberCellData) -> Self {
    let mut cell = new_cell_builder(FieldType::Number);
    cell.insert(CELL_DATA.into(), data.0.into());
    cell
  }
}

impl std::convert::From<String> for NumberCellData {
  fn from(s: String) -> Self {
    Self(s)
  }
}

impl ToString for NumberCellData {
  fn to_string(&self) -> String {
    self.0.clone()
  }
}

impl TypeOption for NumberTypeOption {
  type CellData = NumberCellData;
  type CellChangeset = NumberCellChangeset;
  type CellProtobufType = ProtobufStr;
  type CellFilter = NumberFilterPB;
}

impl TypeOptionCellDataSerde for NumberTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    ProtobufStr::from(cell_data.0)
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(NumberCellData::from(cell))
  }
}

#[async_trait]
impl TypeOptionTransform for NumberTypeOption {
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

        info!(
          "Transforming RichText to NumberTypeOption, updating {} row's cell content",
          rows.len()
        );
        for (row_id, cell_data) in rows {
          if let Ok(num_cell) = self
            .parse_cell(&cell_data)
            .and_then(|num_cell_data| self.format_cell_data(num_cell_data).map_err(Into::into))
          {
            database
              .update_row(row_id, |row| {
                row.update_cells(|cell| {
                  cell.insert(field_id, NumberCellData::from(num_cell.to_string()));
                });
              })
              .await;
          }
        }
      },
      _ => {
        // do nothing
      },
    }
  }
}

impl CellDataDecoder for NumberTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    let num_cell_data = self.parse_cell(cell)?;
    Ok(NumberCellData::from(
      self.format_cell_data(num_cell_data)?.to_string(),
    ))
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    match self.format_cell_data(cell_data) {
      Ok(cell_data) => cell_data.to_string(),
      Err(_) => "".to_string(),
    }
  }

  fn decode_cell_with_transform(
    &self,
    cell: &Cell,
    _from_field_type: FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    let num_cell = Self::CellData::from(cell);
    Some(Self::CellData::from(
      self.format_cell_data(num_cell).ok()?.to_string(),
    ))
  }

  fn numeric_cell(&self, cell: &Cell) -> Option<f64> {
    let num_cell_data = self.parse_cell(cell).ok()?;
    num_cell_data.0.parse::<f64>().ok()
  }
}

pub type NumberCellChangeset = String;

impl CellDataChangeset for NumberTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let num_str = changeset.trim().to_string();
    let number_cell_data = NumberCellData(num_str);
    let formatter = self.format_cell_data(&number_cell_data)?;

    tracing::trace!("number: {:?}", number_cell_data);
    match self.format {
      NumberFormat::Num => Ok((
        NumberCellData(formatter.to_string()).into(),
        NumberCellData::from(formatter.to_string()),
      )),
      _ => Ok((
        NumberCellData::from(formatter.to_unformatted_string()).into(),
        NumberCellData::from(formatter.to_string()),
      )),
    }
  }
}

impl TypeOptionCellDataFilter for NumberTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    match self.format_cell_data(cell_data) {
      Ok(cell_data) => filter.is_visible(&cell_data).unwrap_or(true),
      Err(_) => true,
    }
  }
}

impl TypeOptionCellDataCompare for NumberTypeOption {
  /// Compares two cell data using a specified sort condition.
  ///
  /// The function checks if either `cell_data` or `other_cell_data` is empty (using the `is_empty` method) and:
  /// - If both are empty, it returns `Ordering::Equal`.
  /// - If only the left cell is empty, it returns `Ordering::Greater`.
  /// - If only the right cell is empty, it returns `Ordering::Less`.
  /// - If neither is empty, the cell data is converted into `NumberCellFormat` and compared based on the decimal value.
  ///
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
        let left = NumberCellFormat::from_format_str(&cell_data.0, &self.format);
        let right = NumberCellFormat::from_format_str(&other_cell_data.0, &self.format);
        match (left, right) {
          (Ok(left), Ok(right)) => {
            let order = left.decimal().cmp(right.decimal());
            sort_condition.evaluate_order(order)
          },
          (Ok(_), Err(_)) => Ordering::Less,
          (Err(_), Ok(_)) => Ordering::Greater,
          (Err(_), Err(_)) => Ordering::Equal,
        }
      },
    }
  }
}

lazy_static! {
  static ref SCIENTIFIC_NOTATION_REGEX: Regex = Regex::new(r"([+-]?\d*\.?\d+)e([+-]?\d+)").unwrap();
  pub(crate) static ref EXTRACT_NUM_REGEX: Regex = Regex::new(r"-?\d+(\.\d+)?").unwrap();
  pub(crate) static ref START_WITH_DOT_NUM_REGEX: Regex = Regex::new(r"^\.\d+").unwrap();
}
