use crate::services::cell::{CellBytesCustomParser, CellProtobufBlobParser};
use crate::services::field::number_currency::Currency;
use crate::services::field::{NumberFormat, EXTRACT_NUM_REGEX, START_WITH_DOT_NUM_REGEX};
use bytes::Bytes;
use flowy_error::FlowyResult;
use rust_decimal::Decimal;
use rusty_money::Money;
use std::str::FromStr;

#[derive(Debug, Default)]
pub struct NumberCellFormat {
  decimal: Option<Decimal>,
  money: Option<String>,
}

impl NumberCellFormat {
  pub fn new() -> Self {
    Self {
      decimal: Default::default(),
      money: None,
    }
  }

  /// The num_str might contain currency symbol, e.g. $1,000.00
  pub fn from_format_str(num_str: &str, format: &NumberFormat) -> FlowyResult<Self> {
    if num_str.is_empty() {
      return Ok(Self::default());
    }
    // If the first char is not '-', then it is a sign.
    let sign_positive = match num_str.find('-') {
      None => true,
      Some(offset) => offset != 0,
    };

    let num_str = auto_fill_zero_at_start_if_need(num_str);
    let num_str = extract_number(&num_str);
    match Decimal::from_str(&num_str) {
      Ok(mut decimal) => {
        decimal.set_sign_positive(sign_positive);
        let money = Money::from_decimal(decimal, format.currency());
        Ok(Self::from_money(money))
      },
      Err(_) => match Money::from_str(&num_str, format.currency()) {
        Ok(money) => Ok(Self::from_money(money)),
        Err(_) => Ok(Self::default()),
      },
    }
  }

  pub fn from_decimal(decimal: Decimal) -> Self {
    Self {
      decimal: Some(decimal),
      money: None,
    }
  }

  pub fn from_money(money: Money<Currency>) -> Self {
    Self {
      decimal: Some(*money.amount()),
      money: Some(money.to_string()),
    }
  }

  pub fn decimal(&self) -> &Option<Decimal> {
    &self.decimal
  }

  pub fn is_empty(&self) -> bool {
    self.decimal.is_none()
  }

  pub fn to_unformatted_string(&self) -> String {
    match self.decimal {
      None => String::default(),
      Some(decimal) => decimal.to_string(),
    }
  }
}

fn auto_fill_zero_at_start_if_need(num_str: &str) -> String {
  match START_WITH_DOT_NUM_REGEX.captures(num_str) {
    Ok(Some(captures)) => match captures.get(0).map(|m| m.as_str().to_string()) {
      Some(s) => format!("0{}", s),
      None => num_str.to_string(),
    },
    _ => num_str.to_string(),
  }
}

fn extract_number(num_str: &str) -> String {
  let mut matches = EXTRACT_NUM_REGEX.find_iter(num_str);
  let mut values = vec![];
  while let Some(Ok(m)) = matches.next() {
    values.push(m.as_str().to_string());
  }
  values.join("")
}

impl ToString for NumberCellFormat {
  fn to_string(&self) -> String {
    match &self.money {
      None => match self.decimal {
        None => String::default(),
        Some(decimal) => decimal.to_string(),
      },
      Some(money) => money.to_string(),
    }
  }
}

pub struct NumberCellDataParser();
impl CellProtobufBlobParser for NumberCellDataParser {
  type Object = NumberCellFormat;
  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    match String::from_utf8(bytes.to_vec()) {
      Ok(s) => NumberCellFormat::from_format_str(&s, &NumberFormat::Num),
      Err(_) => Ok(NumberCellFormat::default()),
    }
  }
}

pub struct NumberCellCustomDataParser(pub NumberFormat);
impl CellBytesCustomParser for NumberCellCustomDataParser {
  type Object = NumberCellFormat;
  fn parse(&self, bytes: &Bytes) -> FlowyResult<Self::Object> {
    match String::from_utf8(bytes.to_vec()) {
      Ok(s) => NumberCellFormat::from_format_str(&s, &self.0),
      Err(_) => Ok(NumberCellFormat::default()),
    }
  }
}
