use crate::entities::{FieldType, NumberFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::{
  NumberCellFormat, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionTransform,
};
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};

use crate::services::field::type_options::util::ProtobufStr;
use collab::core::lib0_any_ext::Lib0AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};
use fancy_regex::Regex;
use flowy_error::FlowyResult;
use lazy_static::lazy_static;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::default::Default;
use std::str::FromStr;

// Number
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct NumberTypeOption {
  pub format: NumberFormat,
  pub scale: u32,
  pub symbol: String,
  pub sign_positive: bool,
  pub name: String,
}

#[derive(Clone, Debug, Default)]
pub struct NumberCellData(pub String);

impl From<&Cell> for NumberCellData {
  fn from(cell: &Cell) -> Self {
    Self(cell.get_str_value("data").unwrap_or_default())
  }
}

impl From<NumberCellData> for Cell {
  fn from(data: NumberCellData) -> Self {
    new_cell_builder(FieldType::Number)
      .insert("data", data.0)
      .build()
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
    let format = data
      .get_i64_value("format")
      .map(NumberFormat::from)
      .unwrap_or_default();
    let scale = data.get_i64_value("scale").unwrap_or_default() as u32;
    let symbol = data.get_str_value("symbol").unwrap_or_default();
    let sign_positive = data.get_bool_value("sign_positive").unwrap_or_default();
    let name = data.get_str_value("name").unwrap_or_default();
    Self {
      format,
      scale,
      symbol,
      sign_positive,
      name,
    }
  }
}

impl From<NumberTypeOption> for TypeOptionData {
  fn from(data: NumberTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert("format", data.format.value())
      .insert("scale", data.scale)
      .insert("sign_positive", data.sign_positive)
      .insert("name", data.name)
      .insert("symbol", data.symbol)
      .build()
  }
}

impl TypeOptionCellData for NumberTypeOption {
  fn convert_to_protobuf(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    ProtobufStr::from(cell_data.0)
  }

  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(NumberCellData::from(cell))
  }
}

impl NumberTypeOption {
  pub fn new() -> Self {
    Self::default()
  }

  pub(crate) fn format_cell_data(
    &self,
    num_cell_data: &NumberCellData,
  ) -> FlowyResult<NumberCellFormat> {
    match self.format {
      NumberFormat::Num => {
        if SCIENTIFIC_NOTATION_REGEX
          .is_match(&num_cell_data.0)
          .unwrap()
        {
          match Decimal::from_scientific(&num_cell_data.0.to_lowercase()) {
            Ok(value, ..) => Ok(NumberCellFormat::from_decimal(value)),
            Err(_) => Ok(NumberCellFormat::new()),
          }
        } else {
          let draw_numer_string = NUM_REGEX.replace_all(&num_cell_data.0, "");
          let strnum = match draw_numer_string.matches('.').count() {
            0 | 1 => draw_numer_string.to_string(),
            _ => match EXTRACT_NUM_REGEX.captures(&draw_numer_string) {
              Ok(captures) => match captures {
                Some(capture) => capture[1].to_string(),
                None => "".to_string(),
              },
              Err(_) => "".to_string(),
            },
          };
          match Decimal::from_str(&strnum) {
            Ok(value, ..) => Ok(NumberCellFormat::from_decimal(value)),
            Err(_) => Ok(NumberCellFormat::new()),
          }
        }
      },
      _ => NumberCellFormat::from_format_str(&num_cell_data.0, self.sign_positive, &self.format),
    }
  }

  pub fn set_format(&mut self, format: NumberFormat) {
    self.format = format;
    self.symbol = format.symbol();
  }
}

pub(crate) fn strip_currency_symbol<T: ToString>(s: T) -> String {
  let mut s = s.to_string();
  for symbol in CURRENCY_SYMBOL.iter() {
    if s.starts_with(symbol) {
      s = s.strip_prefix(symbol).unwrap_or("").to_string();
      break;
    }
  }
  s
}

impl TypeOptionTransform for NumberTypeOption {}

impl CellDataDecoder for NumberTypeOption {
  fn decode_cell_str(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    if decoded_field_type.is_date() {
      return Ok(Default::default());
    }

    let num_cell_data = self.decode_cell(cell)?;
    Ok(NumberCellData::from(
      self.format_cell_data(&num_cell_data)?.to_string(),
    ))
  }

  fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    match self.format_cell_data(&cell_data) {
      Ok(cell_data) => cell_data.to_string(),
      Err(_) => "".to_string(),
    }
  }

  fn decode_cell_to_str(&self, cell: &Cell) -> String {
    let cell_data = Self::CellData::from(cell);
    self.decode_cell_data_to_str(cell_data)
  }
}

pub type NumberCellChangeset = String;

impl CellDataChangeset for NumberTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    let number_cell_data = NumberCellData(changeset.trim().to_string());
    let formatter = self.format_cell_data(&number_cell_data)?;

    match self.format {
      NumberFormat::Num => Ok((
        NumberCellData(formatter.to_string()).into(),
        NumberCellData::from(formatter.to_string()),
      )),
      _ => Ok((
        NumberCellData::default().into(),
        NumberCellData::from(formatter.to_string()),
      )),
    }
  }
}

impl TypeOptionCellDataFilter for NumberTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_number() {
      return true;
    }
    match self.format_cell_data(cell_data) {
      Ok(cell_data) => filter.is_visible(&cell_data),
      Err(_) => true,
    }
  }
}

impl TypeOptionCellDataCompare for NumberTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    cell_data.0.cmp(&other_cell_data.0)
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
      sign_positive: true,
      name: "Number".to_string(),
    }
  }
}

lazy_static! {
  static ref NUM_REGEX: Regex = Regex::new(r"[^\d\.]").unwrap();
}

lazy_static! {
  static ref SCIENTIFIC_NOTATION_REGEX: Regex = Regex::new(r"([+-]?\d*\.?\d+)e([+-]?\d+)").unwrap();
}

lazy_static! {
  static ref EXTRACT_NUM_REGEX: Regex = Regex::new(r"^(\d+\.\d+)(?:\.\d+)*$").unwrap();
}
