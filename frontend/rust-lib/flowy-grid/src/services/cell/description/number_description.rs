use crate::impl_from_and_to_type_option;
use crate::services::row::StringifyCellData;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{Field, FieldType};
use lazy_static::lazy_static;
use rust_decimal::prelude::Zero;
use rust_decimal::Decimal;
use rusty_money::iso::{Currency, CNY, EUR, USD};
use serde::{Deserialize, Serialize};

use std::str::FromStr;
use strum::IntoEnumIterator;
use strum_macros::EnumIter;

lazy_static! {
    static ref STRIP_SYMBOL: Vec<String> = make_strip_symbol();
}

#[derive(Clone, Copy, Debug, EnumIter, Serialize, Deserialize, ProtoBuf_Enum)]
pub enum NumberFormat {
    Number = 0,
    USD = 1,
    CNY = 2,
    EUR = 3,
}

impl std::default::Default for NumberFormat {
    fn default() -> Self {
        NumberFormat::Number
    }
}

impl NumberFormat {
    pub fn symbol(&self) -> String {
        match self {
            NumberFormat::Number => "".to_string(),
            NumberFormat::USD => USD.symbol.to_string(),
            NumberFormat::CNY => CNY.symbol.to_string(),
            NumberFormat::EUR => EUR.symbol.to_string(),
        }
    }

    #[allow(dead_code)]
    pub fn code(&self) -> String {
        match self {
            NumberFormat::Number => "".to_string(),
            NumberFormat::USD => USD.iso_alpha_code.to_string(),
            NumberFormat::CNY => CNY.iso_alpha_code.to_string(),
            NumberFormat::EUR => EUR.iso_alpha_code.to_string(),
        }
    }
}

// Number
#[derive(Clone, Debug, Serialize, Deserialize, ProtoBuf)]
pub struct NumberDescription {
    #[pb(index = 1)]
    pub format: NumberFormat,

    #[pb(index = 2)]
    pub scale: u32,

    #[pb(index = 3)]
    pub symbol: String,

    #[pb(index = 4)]
    pub sign_positive: bool,

    #[pb(index = 5)]
    pub name: String,
}
impl_from_and_to_type_option!(NumberDescription, FieldType::Number);

impl std::default::Default for NumberDescription {
    fn default() -> Self {
        let format = NumberFormat::default();
        let symbol = format.symbol();
        NumberDescription {
            format,
            scale: 0,
            symbol,
            sign_positive: true,
            name: "Number".to_string(),
        }
    }
}

impl NumberDescription {
    pub fn set_format(&mut self, format: NumberFormat) {
        self.format = format;
        self.symbol = format.symbol();
    }

    fn decimal_from_str(&self, s: &str) -> Decimal {
        let mut decimal = Decimal::from_str(s).unwrap_or(Decimal::zero());
        match decimal.set_scale(self.scale) {
            Ok(_) => {}
            Err(e) => {
                tracing::error!("Set decimal scale failed: {:?}", e);
            }
        }
        decimal.set_sign_positive(self.sign_positive);
        decimal
    }

    fn money_from_str(&self, s: &str, currency: &'static Currency) -> String {
        let decimal = self.decimal_from_str(s);
        let money = rusty_money::Money::from_decimal(decimal, currency);
        money.to_string()
    }

    fn strip_symbol(&self, s: &str) -> String {
        let mut s = String::from(s);
        if !s.chars().all(char::is_numeric) {
            s.retain(|c| !STRIP_SYMBOL.contains(&c.to_string()));
        }
        s
    }
}

impl StringifyCellData for NumberDescription {
    fn str_from_cell_data(&self, data: String) -> String {
        match self.format {
            NumberFormat::Number => data,
            NumberFormat::USD => self.money_from_str(&data, USD),
            NumberFormat::CNY => self.money_from_str(&data, CNY),
            NumberFormat::EUR => self.money_from_str(&data, EUR),
        }
    }

    fn str_to_cell_data(&self, s: &str) -> Result<String, FlowyError> {
        Ok(self.strip_symbol(s))
    }
}

fn make_strip_symbol() -> Vec<String> {
    let mut symbols = vec![",".to_owned(), ".".to_owned()];
    for format in NumberFormat::iter() {
        symbols.push(format.symbol());
    }
    symbols
}

#[cfg(test)]
mod tests {
    use crate::services::cell::{NumberDescription, NumberFormat};
    use crate::services::row::StringifyCellData;
    use strum::IntoEnumIterator;

    #[test]
    fn number_description_test() {
        let mut description = NumberDescription::default();
        assert_eq!(description.str_to_cell_data("¥18,443").unwrap(), "18443".to_owned());
        assert_eq!(description.str_to_cell_data("$18,443").unwrap(), "18443".to_owned());
        assert_eq!(description.str_to_cell_data("€18.443").unwrap(), "18443".to_owned());

        for format in NumberFormat::iter() {
            description.format = format;
            match format {
                NumberFormat::Number => {
                    assert_eq!(description.str_from_cell_data("18443".to_owned()), "18443".to_owned());
                }
                NumberFormat::USD => {
                    assert_eq!(description.str_from_cell_data("18443".to_owned()), "$18,443".to_owned());
                }
                NumberFormat::CNY => {
                    assert_eq!(description.str_from_cell_data("18443".to_owned()), "¥18,443".to_owned());
                }
                NumberFormat::EUR => {
                    assert_eq!(description.str_from_cell_data("18443".to_owned()), "€18.443".to_owned());
                }
            }
        }
    }

    #[test]
    fn number_description_scale_test() {
        let mut description = NumberDescription::default();
        description.scale = 1;

        for format in NumberFormat::iter() {
            description.format = format;
            match format {
                NumberFormat::Number => {
                    assert_eq!(description.str_from_cell_data("18443".to_owned()), "18443".to_owned());
                }
                NumberFormat::USD => {
                    assert_eq!(
                        description.str_from_cell_data("18443".to_owned()),
                        "$1,844.3".to_owned()
                    );
                }
                NumberFormat::CNY => {
                    assert_eq!(
                        description.str_from_cell_data("18443".to_owned()),
                        "¥1,844.3".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        description.str_from_cell_data("18443".to_owned()),
                        "€1.844,3".to_owned()
                    );
                }
            }
        }
    }

    #[test]
    fn number_description_sign_test() {
        let mut description = NumberDescription::default();
        description.sign_positive = false;

        for format in NumberFormat::iter() {
            description.format = format;
            match format {
                NumberFormat::Number => {
                    assert_eq!(description.str_from_cell_data("18443".to_owned()), "18443".to_owned());
                }
                NumberFormat::USD => {
                    assert_eq!(
                        description.str_from_cell_data("18443".to_owned()),
                        "-$18,443".to_owned()
                    );
                }
                NumberFormat::CNY => {
                    assert_eq!(
                        description.str_from_cell_data("18443".to_owned()),
                        "-¥18,443".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        description.str_from_cell_data("18443".to_owned()),
                        "-€18.443".to_owned()
                    );
                }
            }
        }
    }
}
