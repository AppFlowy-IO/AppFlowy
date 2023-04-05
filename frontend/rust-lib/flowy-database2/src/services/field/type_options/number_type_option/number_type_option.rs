use crate::entities::{FieldType, NumberFilterPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder, TypeCellData};
use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::{
  NumberCellData, StrCellData, TypeOption, TypeOptionCellData, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionTransform,
};
use collab_database::fields::{Field, TypeOptionData};

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

impl TypeOption for NumberTypeOption {
  type CellData = StrCellData;
  type CellChangeset = NumberCellChangeset;
  type CellProtobufType = StrCellData;
  type CellFilter = NumberFilterPB;
}

impl From<TypeOptionData> for NumberTypeOption {
  fn from(_: TypeOptionData) -> Self {
    todo!()
  }
}

impl From<NumberTypeOption> for TypeOptionData {
  fn from(_: NumberTypeOption) -> Self {
    todo!()
  }
}

impl TypeOptionCellData for NumberTypeOption {
  fn convert_to_protobuf(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    cell_data
  }

  fn decode_type_option_cell_str(
    &self,
    cell_str: String,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(StrCellData::from(cell_str))
  }
}

impl NumberTypeOption {
  pub fn new() -> Self {
    Self::default()
  }

  pub(crate) fn format_cell_data(&self, s: &str) -> FlowyResult<NumberCellData> {
    match self.format {
      NumberFormat::Num => {
        if SCIENTIFIC_NOTATION_REGEX.is_match(s).unwrap() {
          match Decimal::from_scientific(&s.to_lowercase()) {
            Ok(value, ..) => Ok(NumberCellData::from_decimal(value)),
            Err(_) => Ok(NumberCellData::new()),
          }
        } else {
          let draw_numer_string = NUM_REGEX.replace_all(s, "");
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
            Ok(value, ..) => Ok(NumberCellData::from_decimal(value)),
            Err(_) => Ok(NumberCellData::new()),
          }
        }
      },
      _ => NumberCellData::from_format_str(s, self.sign_positive, &self.format),
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
    cell_str: String,
    decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    if decoded_field_type.is_date() {
      return Ok(Default::default());
    }

    let str_cell_data = self.decode_type_option_cell_str(cell_str)?;
    let s = StrCellData::from(self.format_cell_data(&str_cell_data)?.to_string());
    Ok(s)
  }

  fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    match self.format_cell_data(&cell_data) {
      Ok(cell_data) => cell_data.to_string(),
      Err(_) => "".to_string(),
    }
  }
}

pub type NumberCellChangeset = String;

impl CellDataChangeset for NumberTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    _type_cell_data: Option<TypeCellData>,
  ) -> FlowyResult<(String, <Self as TypeOption>::CellData)> {
    let data = changeset.trim().to_string();
    let number_cell_data = self.format_cell_data(&data)?;

    match self.format {
      NumberFormat::Num => Ok((
        number_cell_data.to_string(),
        StrCellData::from(number_cell_data.to_string()),
      )),
      _ => Ok((data, StrCellData::from(number_cell_data.to_string()))),
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
