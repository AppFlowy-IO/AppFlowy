#![allow(clippy::upper_case_acronyms)]
use crate::impl_from_and_to_type_option;
use crate::services::field::StringifyCellData;
use crate::services::util::*;
use bytes::Bytes;
use chrono::format::strftime::StrftimeItems;
use chrono::NaiveDateTime;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{AnyData, Field, FieldType};
use rust_decimal::Decimal;
use rusty_money::{
    iso::{Currency, CNY, EUR, USD},
    Money,
};
use std::str::FromStr;
use strum_macros::EnumIter;

#[derive(Debug, Clone, ProtoBuf, Default)]
pub struct RichTextDescription {
    #[pb(index = 1)]
    pub format: String,
}
impl_from_and_to_type_option!(RichTextDescription, FieldType::RichText);

impl StringifyCellData for RichTextDescription {
    fn str_from_cell_data(&self, data: AnyData) -> String {
        data.to_string()
    }

    fn str_to_cell_data(&self, s: &str) -> Result<AnyData, FlowyError> {
        Ok(AnyData::from_str(self.field_type(), s))
    }
}

// Checkbox
#[derive(Debug, Clone, ProtoBuf, Default)]
pub struct CheckboxDescription {
    #[pb(index = 1)]
    pub is_selected: bool,
}
impl_from_and_to_type_option!(CheckboxDescription, FieldType::Checkbox);

impl StringifyCellData for CheckboxDescription {
    fn str_from_cell_data(&self, data: AnyData) -> String {
        data.to_string()
    }

    fn str_to_cell_data(&self, s: &str) -> Result<AnyData, FlowyError> {
        let s = match string_to_bool(s) {
            true => "1",
            false => "0",
        };
        Ok(AnyData::from_str(self.field_type(), s))
    }
}

// Date
#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct DateDescription {
    #[pb(index = 1)]
    pub date_format: DateFormat,

    #[pb(index = 2)]
    pub time_format: TimeFormat,
}
impl_from_and_to_type_option!(DateDescription, FieldType::DateTime);

impl DateDescription {
    fn date_time_format_str(&self) -> String {
        format!("{} {}", self.date_format.format_str(), self.time_format.format_str())
    }

    #[allow(dead_code)]
    fn today_from_timestamp(&self, timestamp: i64) -> String {
        let native = chrono::NaiveDateTime::from_timestamp(timestamp, 0);
        self.today_from_native(native)
    }

    fn today_from_native(&self, naive: chrono::NaiveDateTime) -> String {
        let utc: chrono::DateTime<chrono::Utc> = chrono::DateTime::from_utc(naive, chrono::Utc);
        let local: chrono::DateTime<chrono::Local> = chrono::DateTime::from(utc);

        let fmt_str = self.date_time_format_str();
        let output = format!("{}", local.format_with_items(StrftimeItems::new(&fmt_str)));
        output
    }
}

impl StringifyCellData for DateDescription {
    fn str_from_cell_data(&self, data: AnyData) -> String {
        match String::from_utf8(data.value) {
            Ok(s) => match s.parse::<i64>() {
                Ok(timestamp) => {
                    let native = NaiveDateTime::from_timestamp(timestamp, 0);
                    self.today_from_native(native)
                }
                Err(e) => {
                    tracing::debug!("DateDescription format {} fail. error: {:?}", s, e);
                    String::new()
                }
            },
            Err(e) => {
                tracing::error!("DateDescription stringify any_data failed. {:?}", e);
                String::new()
            }
        }
    }

    fn str_to_cell_data(&self, s: &str) -> Result<AnyData, FlowyError> {
        let timestamp = s
            .parse::<i64>()
            .map_err(|e| FlowyError::internal().context(format!("Parse {} to i64 failed: {}", s, e)))?;
        Ok(AnyData::from_str(self.field_type(), &format!("{}", timestamp)))
    }
}

#[derive(Clone, Debug, Copy, ProtoBuf_Enum)]
pub enum DateFormat {
    Local = 0,
    US = 1,
    ISO = 2,
    Friendly = 3,
}
impl std::default::Default for DateFormat {
    fn default() -> Self {
        DateFormat::Friendly
    }
}

impl std::convert::From<i32> for DateFormat {
    fn from(value: i32) -> Self {
        match value {
            0 => DateFormat::Local,
            1 => DateFormat::US,
            2 => DateFormat::ISO,
            3 => DateFormat::Friendly,
            _ => {
                tracing::error!("Unsupported date format, fallback to friendly");
                DateFormat::Friendly
            }
        }
    }
}

impl DateFormat {
    pub fn value(&self) -> i32 {
        *self as i32
    }
    // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
    pub fn format_str(&self) -> &'static str {
        match self {
            DateFormat::Local => "%Y/%m/%d",
            DateFormat::US => "%Y/%m/%d",
            DateFormat::ISO => "%Y-%m-%d",
            DateFormat::Friendly => "%b %d,%Y",
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, ProtoBuf_Enum)]
pub enum TimeFormat {
    TwelveHour = 0,
    TwentyFourHour = 1,
}

impl std::convert::From<i32> for TimeFormat {
    fn from(value: i32) -> Self {
        match value {
            0 => TimeFormat::TwelveHour,
            1 => TimeFormat::TwentyFourHour,
            _ => {
                tracing::error!("Unsupported time format, fallback to TwentyFourHour");
                TimeFormat::TwentyFourHour
            }
        }
    }
}

impl TimeFormat {
    pub fn value(&self) -> i32 {
        *self as i32
    }

    // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
    pub fn format_str(&self) -> &'static str {
        match self {
            TimeFormat::TwelveHour => "%r",
            TimeFormat::TwentyFourHour => "%R",
        }
    }
}

impl std::default::Default for TimeFormat {
    fn default() -> Self {
        TimeFormat::TwentyFourHour
    }
}

// Single select
#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct SingleSelectDescription {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_from_and_to_type_option!(SingleSelectDescription, FieldType::SingleSelect);

impl StringifyCellData for SingleSelectDescription {
    fn str_from_cell_data(&self, data: AnyData) -> String {
        data.to_string()
    }

    fn str_to_cell_data(&self, s: &str) -> Result<AnyData, FlowyError> {
        Ok(AnyData::from_str(self.field_type(), s))
    }
}

// Multiple select
#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct MultiSelectDescription {
    #[pb(index = 1)]
    pub options: Vec<SelectOption>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_from_and_to_type_option!(MultiSelectDescription, FieldType::MultiSelect);
impl StringifyCellData for MultiSelectDescription {
    fn str_from_cell_data(&self, data: AnyData) -> String {
        data.to_string()
    }

    fn str_to_cell_data(&self, s: &str) -> Result<AnyData, FlowyError> {
        Ok(AnyData::from_str(self.field_type(), s))
    }
}

#[derive(Clone, Debug, ProtoBuf, Default)]
pub struct SelectOption {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub color: String,
}

impl SelectOption {
    pub fn new(name: &str) -> Self {
        SelectOption {
            id: uuid(),
            name: name.to_owned(),
            color: "".to_string(),
        }
    }
}

// Number
#[derive(Clone, Debug, ProtoBuf)]
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
    fn str_from_cell_data(&self, data: AnyData) -> String {
        match String::from_utf8(data.value) {
            Ok(s) => match self.money_from_str(&s) {
                Some(money_str) => money_str,
                None => String::default(),
            },
            Err(e) => {
                tracing::error!("NumberDescription stringify any_data failed. {:?}", e);
                String::new()
            }
        }
    }

    fn str_to_cell_data(&self, s: &str) -> Result<AnyData, FlowyError> {
        let strip_symbol_money = strip_money_symbol(s);
        let decimal = Decimal::from_str(&strip_symbol_money).map_err(|err| FlowyError::internal().context(err))?;
        let money_str = decimal.to_string();
        Ok(AnyData::from_str(self.field_type(), &money_str))
    }
}

#[derive(Clone, Copy, Debug, EnumIter, ProtoBuf_Enum)]
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
