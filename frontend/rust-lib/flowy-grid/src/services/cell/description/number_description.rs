use crate::impl_from_and_to_type_option;
use crate::services::row::StringifyCellData;
use crate::services::util::*;
use chrono::format::strftime::StrftimeItems;
use chrono::NaiveDateTime;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{Field, FieldType};
use rust_decimal::Decimal;
use rusty_money::{
    iso::{Currency, CNY, EUR, USD},
    Money,
};
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use strum_macros::EnumIter;

// Number
#[derive(Clone, Debug, Serialize, Deserialize, ProtoBuf)]
pub struct NumberDescription {
    #[pb(index = 1)]
    pub money: MoneySymbol,

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
        let money = MoneySymbol::default();
        let symbol = money.symbol_str();
        NumberDescription {
            money,
            scale: 0,
            symbol,
            sign_positive: true,
            name: "Number".to_string(),
        }
    }
}

impl NumberDescription {
    pub fn set_money_symbol(&mut self, money_symbol: MoneySymbol) {
        self.money = money_symbol;
        self.symbol = money_symbol.symbol_str();
    }

    fn money_from_str(&self, s: &str) -> Option<String> {
        match Decimal::from_str(s) {
            Ok(mut decimal) => {
                match decimal.set_scale(self.scale) {
                    Ok(_) => {}
                    Err(e) => {
                        tracing::error!("Set decimal scale failed: {:?}", e);
                    }
                }
                decimal.set_sign_positive(self.sign_positive);
                Some(self.money.with_decimal(decimal).to_string())
            }
            Err(e) => {
                tracing::error!("Parser money from {} failed: {:?}", s, e);
                None
            }
        }
    }
}

impl StringifyCellData for NumberDescription {
    fn str_from_cell_data(&self, data: String) -> String {
        match self.money_from_str(&data) {
            Some(money_str) => money_str,
            None => String::default(),
        }
    }

    fn str_to_cell_data(&self, s: &str) -> Result<String, FlowyError> {
        let strip_symbol_money = strip_money_symbol(s);
        let decimal = Decimal::from_str(&strip_symbol_money).map_err(|err| FlowyError::internal().context(err))?;
        Ok(decimal.to_string())
    }
}

#[derive(Clone, Copy, Debug, EnumIter, Serialize, Deserialize, ProtoBuf_Enum)]
pub enum MoneySymbol {
    CNY = 0,
    EUR = 1,
    USD = 2,
}

impl std::default::Default for MoneySymbol {
    fn default() -> Self {
        MoneySymbol::USD
    }
}

impl MoneySymbol {
    // Currency list https://docs.rs/rusty-money/0.4.0/rusty_money/iso/index.html
    pub fn from_symbol_str(s: &str) -> MoneySymbol {
        match s {
            "CNY" => MoneySymbol::CNY,
            "EUR" => MoneySymbol::EUR,
            "USD" => MoneySymbol::USD,
            _ => MoneySymbol::CNY,
        }
    }

    pub fn from_money(money: &rusty_money::Money<Currency>) -> MoneySymbol {
        MoneySymbol::from_symbol_str(&money.currency().symbol.to_string())
    }

    pub fn currency(&self) -> &'static Currency {
        match self {
            MoneySymbol::CNY => CNY,
            MoneySymbol::EUR => EUR,
            MoneySymbol::USD => USD,
        }
    }

    // string_to_money("¥18,443").unwrap();
    // string_to_money("$18,443").unwrap();
    // string_to_money("€18,443").unwrap();
    pub fn code(&self) -> String {
        self.currency().iso_alpha_code.to_string()
    }

    pub fn symbol_str(&self) -> String {
        self.currency().symbol.to_string()
    }

    pub fn zero(&self) -> Money<Currency> {
        let mut decimal = Decimal::new(0, 0);
        decimal.set_sign_positive(true);
        self.with_decimal(decimal)
    }

    pub fn with_decimal(&self, decimal: Decimal) -> Money<Currency> {
        let money = rusty_money::Money::from_decimal(decimal, self.currency());
        money
    }
}
