use crate::impl_type_option;
use crate::services::row::{CellDataChangeset, CellDataOperation, TypeOptionCellData};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};

use lazy_static::lazy_static;
use rust_decimal::Decimal;
use rusty_money::iso::*;
use serde::{Deserialize, Serialize};

use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use bytes::Bytes;
use std::str::FromStr;
use strum::IntoEnumIterator;
use strum_macros::EnumIter;

lazy_static! {
    static ref STRIP_SYMBOL: Vec<String> = make_strip_symbol();
}

#[derive(Default)]
pub struct NumberTypeOptionBuilder(NumberTypeOption);
impl_into_box_type_option_builder!(NumberTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(NumberTypeOptionBuilder, NumberTypeOption);

impl NumberTypeOptionBuilder {
    pub fn name(mut self, name: &str) -> Self {
        self.0.name = name.to_string();
        self
    }

    pub fn set_format(mut self, format: NumberFormat) -> Self {
        self.0.set_format(format);
        self
    }

    pub fn scale(mut self, scale: u32) -> Self {
        self.0.scale = scale;
        self
    }

    pub fn positive(mut self, positive: bool) -> Self {
        self.0.sign_positive = positive;
        self
    }
}

impl TypeOptionBuilder for NumberTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}

// Number
#[derive(Clone, Debug, Serialize, Deserialize, ProtoBuf)]
pub struct NumberTypeOption {
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
impl_type_option!(NumberTypeOption, FieldType::Number);

impl CellDataOperation for NumberTypeOption {
    fn decode_cell_data(&self, data: String, _field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if type_option_cell_data.is_date() {
                return String::new();
            }

            let cell_data = type_option_cell_data.data;
            match self.format {
                NumberFormat::Number | NumberFormat::Percent => {
                    if cell_data.parse::<i64>().is_ok() {
                        cell_data
                    } else {
                        String::new()
                    }
                }
                _ => self.money_from_str(&cell_data, self.format.currency()),
            }
        } else {
            String::new()
        }
    }

    fn apply_changeset<T: Into<CellDataChangeset>>(
        &self,
        changeset: T,
        _cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.into();
        let data = self.strip_symbol(changeset);

        if !data.chars().all(char::is_numeric) {
            return Err(FlowyError::invalid_data().context("Should only contain numbers"));
        }

        Ok(TypeOptionCellData::new(&data, self.field_type()).json())
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

impl NumberTypeOption {
    pub fn set_format(&mut self, format: NumberFormat) {
        self.format = format;
        self.symbol = format.symbol();
    }

    fn money_from_str(&self, s: &str, currency: &'static Currency) -> String {
        match Decimal::from_str(s) {
            Ok(mut decimal) => {
                match decimal.set_scale(self.scale) {
                    Ok(_) => {}
                    Err(e) => {
                        tracing::error!("Set decimal scale failed: {:?}", e);
                    }
                }
                decimal.set_sign_positive(self.sign_positive);
                let money = rusty_money::Money::from_decimal(decimal, currency);
                money.to_string()
            }
            Err(_) => String::new(),
        }
    }

    fn strip_symbol<T: ToString>(&self, s: T) -> String {
        let mut s = s.to_string();
        if !s.chars().all(char::is_numeric) {
            s.retain(|c| !STRIP_SYMBOL.contains(&c.to_string()));
        }
        s
    }
}

#[derive(Clone, Copy, Debug, EnumIter, Serialize, Deserialize, ProtoBuf_Enum)]
pub enum NumberFormat {
    Number = 0,
    USD = 1,
    CanadianDollar = 2,
    EUR = 4,
    Pound = 5,
    Yen = 6,
    Ruble = 7,
    Rupee = 8,
    Won = 9,
    Yuan = 10,
    Real = 11,
    Lira = 12,
    Rupiah = 13,
    Franc = 14,
    HongKongDollar = 15,
    NewZealandDollar = 16,
    Krona = 17,
    NorwegianKrone = 18,
    MexicanPeso = 19,
    Rand = 20,
    NewTaiwanDollar = 21,
    DanishKrone = 22,
    Baht = 23,
    Forint = 24,
    Koruna = 25,
    Shekel = 26,
    ChileanPeso = 27,
    PhilippinePeso = 28,
    Dirham = 29,
    ColombianPeso = 30,
    Riyal = 31,
    Ringgit = 32,
    Leu = 33,
    ArgentinePeso = 34,
    UruguayanPeso = 35,
    Percent = 36,
}

impl std::default::Default for NumberFormat {
    fn default() -> Self {
        NumberFormat::Number
    }
}

impl NumberFormat {
    pub fn currency(&self) -> &'static Currency {
        match self {
            NumberFormat::Number => USD,
            NumberFormat::USD => USD,
            NumberFormat::CanadianDollar => USD,
            NumberFormat::EUR => EUR,
            NumberFormat::Pound => GIP,
            NumberFormat::Yen => CNY,
            NumberFormat::Ruble => RUB,
            NumberFormat::Rupee => INR,
            NumberFormat::Won => KRW,
            NumberFormat::Yuan => CNY,
            NumberFormat::Real => BRL,
            NumberFormat::Lira => TRY,
            NumberFormat::Rupiah => IDR,
            NumberFormat::Franc => CHF,
            NumberFormat::HongKongDollar => USD,
            NumberFormat::NewZealandDollar => USD,
            NumberFormat::Krona => SEK,
            NumberFormat::NorwegianKrone => NOK,
            NumberFormat::MexicanPeso => USD,
            NumberFormat::Rand => ZAR,
            NumberFormat::NewTaiwanDollar => USD,
            NumberFormat::DanishKrone => DKK,
            NumberFormat::Baht => THB,
            NumberFormat::Forint => HUF,
            NumberFormat::Koruna => CZK,
            NumberFormat::Shekel => CZK,
            NumberFormat::ChileanPeso => CLP,
            NumberFormat::PhilippinePeso => PHP,
            NumberFormat::Dirham => AED,
            NumberFormat::ColombianPeso => COP,
            NumberFormat::Riyal => SAR,
            NumberFormat::Ringgit => MYR,
            NumberFormat::Leu => RON,
            NumberFormat::ArgentinePeso => ARS,
            NumberFormat::UruguayanPeso => UYU,
            NumberFormat::Percent => USD,
        }
    }
    pub fn symbol(&self) -> String {
        match self {
            NumberFormat::Number => "".to_string(),
            NumberFormat::USD => USD.symbol.to_string(),
            NumberFormat::CanadianDollar => format!("CA{}", USD.symbol.to_string()),
            NumberFormat::EUR => EUR.symbol.to_string(),
            NumberFormat::Pound => GIP.symbol.to_string(),
            NumberFormat::Yen => CNY.symbol.to_string(),
            NumberFormat::Ruble => RUB.iso_alpha_code.to_string(),
            NumberFormat::Rupee => INR.symbol.to_string(),
            NumberFormat::Won => KRW.symbol.to_string(),
            NumberFormat::Yuan => format!("CN{}", CNY.symbol.to_string()),
            NumberFormat::Real => BRL.symbol.to_string(),
            NumberFormat::Lira => TRY.iso_alpha_code.to_string(),
            NumberFormat::Rupiah => IDR.iso_alpha_code.to_string(),
            NumberFormat::Franc => CHF.iso_alpha_code.to_string(),
            NumberFormat::HongKongDollar => format!("HK{}", USD.symbol.to_string()),
            NumberFormat::NewZealandDollar => format!("NZ{}", USD.symbol.to_string()),
            NumberFormat::Krona => SEK.iso_alpha_code.to_string(),
            NumberFormat::NorwegianKrone => NOK.iso_alpha_code.to_string(),
            NumberFormat::MexicanPeso => format!("MX{}", USD.symbol.to_string()),
            NumberFormat::Rand => ZAR.iso_alpha_code.to_string(),
            NumberFormat::NewTaiwanDollar => format!("NT{}", USD.symbol.to_string()),
            NumberFormat::DanishKrone => DKK.iso_alpha_code.to_string(),
            NumberFormat::Baht => THB.iso_alpha_code.to_string(),
            NumberFormat::Forint => HUF.iso_alpha_code.to_string(),
            NumberFormat::Koruna => CZK.iso_alpha_code.to_string(),
            NumberFormat::Shekel => CZK.symbol.to_string(),
            NumberFormat::ChileanPeso => CLP.iso_alpha_code.to_string(),
            NumberFormat::PhilippinePeso => PHP.symbol.to_string(),
            NumberFormat::Dirham => AED.iso_alpha_code.to_string(),
            NumberFormat::ColombianPeso => COP.iso_alpha_code.to_string(),
            NumberFormat::Riyal => SAR.iso_alpha_code.to_string(),
            NumberFormat::Ringgit => MYR.iso_alpha_code.to_string(),
            NumberFormat::Leu => RON.iso_alpha_code.to_string(),
            NumberFormat::ArgentinePeso => ARS.iso_alpha_code.to_string(),
            NumberFormat::UruguayanPeso => UYU.iso_alpha_code.to_string(),
            NumberFormat::Percent => "%".to_string(),
        }
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
    use crate::services::field::FieldBuilder;
    use crate::services::field::{NumberFormat, NumberTypeOption};
    use crate::services::row::{CellDataOperation, TypeOptionCellData};
    use flowy_grid_data_model::entities::FieldType;
    use strum::IntoEnumIterator;

    #[test]
    fn number_description_invalid_input_test() {
        let type_option = NumberTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        assert_eq!("".to_owned(), type_option.decode_cell_data(data(""), &field_meta));
        assert_eq!("".to_owned(), type_option.decode_cell_data(data("abc"), &field_meta));
    }

    #[test]
    fn number_description_test() {
        let mut type_option = NumberTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        assert_eq!(type_option.strip_symbol("¥18,443"), "18443".to_owned());
        assert_eq!(type_option.strip_symbol("$18,443"), "18443".to_owned());
        assert_eq!(type_option.strip_symbol("€18.443"), "18443".to_owned());

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Number => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "18443".to_owned()
                    );
                }
                NumberFormat::USD => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "$18,443".to_owned()
                    );
                    assert_eq!(type_option.decode_cell_data(data(""), &field_meta), "".to_owned());
                    assert_eq!(type_option.decode_cell_data(data("abc"), &field_meta), "".to_owned());
                }
                NumberFormat::Yen => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "¥18,443".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "€18.443".to_owned()
                    );
                }
            }
        }
    }

    fn data(s: &str) -> String {
        TypeOptionCellData::new(s, FieldType::Number).json()
    }

    #[test]
    fn number_description_scale_test() {
        let mut type_option = NumberTypeOption {
            scale: 1,
            ..Default::default()
        };
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Number => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "18443".to_owned()
                    );
                }
                NumberFormat::USD => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "$1,844.3".to_owned()
                    );
                }
                NumberFormat::Yen => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "¥1,844.3".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "€1.844,3".to_owned()
                    );
                }
            }
        }
    }

    #[test]
    fn number_description_sign_test() {
        let mut type_option = NumberTypeOption {
            sign_positive: false,
            ..Default::default()
        };
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Number => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "18443".to_owned()
                    );
                }
                NumberFormat::USD => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "-$18,443".to_owned()
                    );
                }
                NumberFormat::Yen => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "-¥18,443".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        type_option.decode_cell_data(data("18443"), &field_meta),
                        "-€18.443".to_owned()
                    );
                }
            }
        }
    }
}
