use collab::preclude::encoding::serde::from_any;
use collab::preclude::Any;
use collab::util::AnyMapExt;
use std::cmp::Ordering;
use std::default::Default;
use std::str::FromStr;

use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::{new_cell_builder, Cell};
use fancy_regex::Regex;
use lazy_static::lazy_static;
use rust_decimal::Decimal;
use serde::{Deserialize, Deserializer, Serialize};

use flowy_error::FlowyResult;

use crate::entities::{FieldType, NumberFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::type_options::util::ProtobufStr;
use crate::services::field::{
  NumberCellFormat, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionCellDataSerde, TypeOptionTransform, CELL_DATA,
};
use crate::services::sort::SortCondition;

// Number
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct NumberTypeOption {
  #[serde(default, deserialize_with = "number_format_from_i64")]
  pub format: NumberFormat,
  #[serde(default)]
  pub scale: u32,
  #[serde(default)]
  pub symbol: String,
  #[serde(default)]
  pub name: String,
}

fn number_format_from_i64<'de, D>(deserializer: D) -> Result<NumberFormat, D::Error>
where
  D: Deserializer<'de>,
{
  let value = i64::deserialize(deserializer)?;
  Ok(NumberFormat::from(value))
}

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

impl From<TypeOptionData> for NumberTypeOption {
  fn from(data: TypeOptionData) -> Self {
    from_any(&Any::from(data)).unwrap()
  }
}

impl From<NumberTypeOption> for TypeOptionData {
  fn from(data: NumberTypeOption) -> Self {
    TypeOptionDataBuilder::from([
      ("format".into(), Any::BigInt(data.format.value())),
      ("scale".into(), Any::BigInt(data.scale as i64)),
      ("name".into(), data.name.into()),
      ("symbol".into(), data.symbol.into()),
    ])
  }
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

impl NumberTypeOption {
  pub fn new() -> Self {
    Self::default()
  }

  fn format_cell_data<T: AsRef<str>>(&self, num_cell_data: T) -> FlowyResult<NumberCellFormat> {
    match self.format {
      NumberFormat::Num => {
        if SCIENTIFIC_NOTATION_REGEX
          .is_match(&num_cell_data.as_ref())
          .unwrap()
        {
          match Decimal::from_scientific(&num_cell_data.as_ref().to_lowercase()) {
            Ok(value, ..) => Ok(NumberCellFormat::from_decimal(value)),
            Err(_) => Ok(NumberCellFormat::new()),
          }
        } else {
          // Test the input string is start with dot and only contains number.
          // If it is, add a 0 before the dot. For example, ".123" -> "0.123"
          let num_str = match START_WITH_DOT_NUM_REGEX.captures(&num_cell_data.as_ref()) {
            Ok(Some(captures)) => match captures.get(0).map(|m| m.as_str().to_string()) {
              Some(s) => {
                format!("0{}", s)
              },
              None => "".to_string(),
            },
            // Extract the number from the string.
            // For example, "123abc" -> "123". check out the number_type_option_input_test test for
            // more examples.
            _ => match EXTRACT_NUM_REGEX.captures(&num_cell_data.as_ref()) {
              Ok(Some(captures)) => captures
                .get(0)
                .map(|m| m.as_str().to_string())
                .unwrap_or_default(),
              _ => "".to_string(),
            },
          };

          match Decimal::from_str(&num_str) {
            Ok(decimal, ..) => Ok(NumberCellFormat::from_decimal(decimal)),
            Err(_) => Ok(NumberCellFormat::new()),
          }
        }
      },
      _ => {
        // If the format is not number, use the format string to format the number.
        NumberCellFormat::from_format_str(&num_cell_data.as_ref(), &self.format)
      },
    }
  }

  pub fn set_format(&mut self, format: NumberFormat) {
    self.format = format;
    self.symbol = format.symbol();
  }
}

impl TypeOptionTransform for NumberTypeOption {}

impl CellDataDecoder for NumberTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    let num_cell_data = self.parse_cell(cell)?;
    Ok(NumberCellData::from(
      self.format_cell_data(&num_cell_data)?.to_string(),
    ))
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    match self.format_cell_data(&cell_data) {
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
      self.format_cell_data(&num_cell).ok()?.to_string(),
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

impl std::default::Default for NumberTypeOption {
  fn default() -> Self {
    let format = NumberFormat::default();
    let symbol = format.symbol();
    NumberTypeOption {
      format,
      scale: 0,
      symbol,
      name: "Number".to_string(),
    }
  }
}

lazy_static! {
  static ref SCIENTIFIC_NOTATION_REGEX: Regex = Regex::new(r"([+-]?\d*\.?\d+)e([+-]?\d+)").unwrap();
  pub(crate) static ref EXTRACT_NUM_REGEX: Regex = Regex::new(r"-?\d+(\.\d+)?").unwrap();
  pub(crate) static ref START_WITH_DOT_NUM_REGEX: Regex = Regex::new(r"^\.\d+").unwrap();
}
