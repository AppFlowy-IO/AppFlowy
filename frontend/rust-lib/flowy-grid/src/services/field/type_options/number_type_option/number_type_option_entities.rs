use crate::services::cell::{CellBytesCustomParser, CellProtobufBlobParser, DecodedCellData};
use crate::services::field::number_currency::Currency;
use crate::services::field::{strip_currency_symbol, NumberFormat, STRIP_SYMBOL};
use bytes::Bytes;
use flowy_error::FlowyResult;
use rust_decimal::Decimal;
use rusty_money::Money;
use std::str::FromStr;

#[derive(Default)]
pub struct NumberCellData {
    decimal: Option<Decimal>,
    money: Option<String>,
}

impl NumberCellData {
    pub fn new() -> Self {
        Self {
            decimal: Default::default(),
            money: None,
        }
    }

    pub fn from_format_str(s: &str, sign_positive: bool, format: &NumberFormat) -> FlowyResult<Self> {
        let mut num_str = strip_currency_symbol(s);
        let currency = format.currency();
        if num_str.is_empty() {
            return Ok(Self::default());
        }
        match Decimal::from_str(&num_str) {
            Ok(mut decimal) => {
                decimal.set_sign_positive(sign_positive);
                let money = Money::from_decimal(decimal, currency);
                Ok(Self::from_money(money))
            }
            Err(_) => match Money::from_str(&num_str, currency) {
                Ok(money) => Ok(NumberCellData::from_money(money)),
                Err(_) => {
                    num_str.retain(|c| !STRIP_SYMBOL.contains(&c.to_string()));
                    if num_str.chars().all(char::is_numeric) {
                        Self::from_format_str(&num_str, sign_positive, format)
                    } else {
                        // returns empty string if it can be formatted
                        Ok(Self::default())
                    }
                }
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
}

// impl FromStr for NumberCellData {
//     type Err = FlowyError;
//
//     fn from_str(s: &str) -> Result<Self, Self::Err> {
//         if s.is_empty() {
//             return Ok(Self::default());
//         }
//         let decimal = Decimal::from_str(s).map_err(internal_error)?;
//         Ok(Self::from_decimal(decimal))
//     }
// }

impl ToString for NumberCellData {
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

impl DecodedCellData for NumberCellData {
    type Object = NumberCellData;

    fn is_empty(&self) -> bool {
        self.decimal.is_none()
    }
}

pub struct NumberCellDataParser();
impl CellProtobufBlobParser for NumberCellDataParser {
    type Object = NumberCellData;
    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => NumberCellData::from_format_str(&s, true, &NumberFormat::Num),
            Err(_) => Ok(NumberCellData::default()),
        }
    }
}

pub struct NumberCellCustomDataParser(pub NumberFormat);
impl CellBytesCustomParser for NumberCellCustomDataParser {
    type Object = NumberCellData;
    fn parse(&self, bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => NumberCellData::from_format_str(&s, true, &self.0),
            Err(_) => Ok(NumberCellData::default()),
        }
    }
}
