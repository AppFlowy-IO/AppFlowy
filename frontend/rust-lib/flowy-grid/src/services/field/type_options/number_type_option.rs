use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellContentChangeset, CellDataOperation, DecodedCellData};
use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
use lazy_static::lazy_static;
use rust_decimal::Decimal;
use rusty_money::define_currency_set;
use serde::{Deserialize, Serialize};
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

impl CellDataOperation<String, String> for NumberTypeOption {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        _field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<String>,
    {
        if decoded_field_type.is_date() {
            return Ok(DecodedCellData::default());
        }

        let cell_data = encoded_data.into();
        match self.format {
            NumberFormat::Number => {
                if let Ok(v) = cell_data.parse::<f64>() {
                    return Ok(DecodedCellData::new(v.to_string()));
                }

                if let Ok(v) = cell_data.parse::<i64>() {
                    return Ok(DecodedCellData::new(v.to_string()));
                }

                Ok(DecodedCellData::default())
            }
            NumberFormat::Percent => {
                let content = cell_data.parse::<f64>().map_or(String::new(), |v| v.to_string());
                Ok(DecodedCellData::new(content))
            }
            _ => {
                let content = self.money_from_str(&cell_data);
                Ok(DecodedCellData::new(content))
            }
        }
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_meta: Option<CellMeta>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let changeset = changeset.into();
        let mut data = changeset.trim().to_string();

        if self.format != NumberFormat::Number {
            data = self.strip_symbol(data);
            if !data.chars().all(char::is_numeric) {
                return Err(FlowyError::invalid_data().context("Should only contain numbers"));
            }
        }

        Ok(data)
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

    fn money_from_str(&self, s: &str) -> String {
        match Decimal::from_str(s) {
            Ok(mut decimal) => {
                match decimal.set_scale(self.scale) {
                    Ok(_) => {}
                    Err(e) => {
                        tracing::error!("Set decimal scale failed: {:?}", e);
                    }
                }

                decimal.set_sign_positive(self.sign_positive);
                let money = rusty_money::Money::from_decimal(decimal, self.format.currency());
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

#[derive(Clone, Copy, Debug, PartialEq, Eq, EnumIter, Serialize, Deserialize, ProtoBuf_Enum)]
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

define_currency_set!(
    number_currency {
        NUMBER : {
            code: "",
            exponent: 2,
            locale: EnEu,
            minor_units: 1,
            name: "number",
            symbol: "RUB",
            symbol_first: false,
        },
        USD : {
            code: "USD",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "United States Dollar",
            symbol: "$",
            symbol_first: true,
        },
        CANADIAN_DOLLAR : {
            code: "USD",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "Canadian Dollar",
            symbol: "CA$",
            symbol_first: true,
        },
         NEW_TAIWAN_DOLLAR : {
            code: "USD",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "NewTaiwan Dollar",
            symbol: "NT$",
            symbol_first: true,
        },
        HONG_KONG_DOLLAR : {
            code: "USD",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "HongKong Dollar",
            symbol: "HZ$",
            symbol_first: true,
        },
        NEW_ZEALAND_DOLLAR : {
            code: "USD",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "NewZealand Dollar",
            symbol: "NZ$",
            symbol_first: true,
        },
        EUR : {
            code: "EUR",
            exponent: 2,
            locale: EnEu,
            minor_units: 1,
            name: "Euro",
            symbol: "€",
            symbol_first: true,
        },
        GIP : {
            code: "GIP",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "Gibraltar Pound",
            symbol: "£",
            symbol_first: true,
        },
        CNY : {
            code: "CNY",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "Chinese Renminbi Yuan",
            symbol: "¥",
            symbol_first: true,
        },
        YUAN : {
            code: "CNY",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "Chinese Renminbi Yuan",
            symbol: "CN¥",
            symbol_first: true,
        },
        RUB : {
            code: "RUB",
            exponent: 2,
            locale: EnEu,
            minor_units: 1,
            name: "Russian Ruble",
            symbol: "RUB",
            symbol_first: false,
        },
        INR : {
            code: "INR",
            exponent: 2,
            locale: EnIn,
            minor_units: 50,
            name: "Indian Rupee",
            symbol: "₹",
            symbol_first: true,
        },
        KRW : {
            code: "KRW",
            exponent: 0,
            locale: EnUs,
            minor_units: 1,
            name: "South Korean Won",
            symbol: "₩",
            symbol_first: true,
        },
        BRL : {
            code: "BRL",
            exponent: 2,
            locale: EnUs,
            minor_units: 5,
            name: "Brazilian real",
            symbol: "R$",
            symbol_first: true,
        },
        TRY : {
            code: "TRY",
            exponent: 2,
            locale: EnEu,
            minor_units: 1,
            name: "Turkish Lira",
            // symbol: "₺",
            symbol: "TRY",
            symbol_first: true,
        },
        IDR : {
            code: "IDR",
            exponent: 2,
            locale: EnUs,
            minor_units: 5000,
            name: "Indonesian Rupiah",
            // symbol: "Rp",
            symbol: "IDR",
            symbol_first: true,
        },
        CHF : {
            code: "CHF",
            exponent: 2,
            locale: EnUs,
            minor_units: 5,
            name: "Swiss Franc",
            // symbol: "Fr",
            symbol: "CHF",
            symbol_first: true,
        },
        SEK : {
            code: "SEK",
            exponent: 2,
            locale: EnBy,
            minor_units: 100,
            name: "Swedish Krona",
            // symbol: "kr",
            symbol: "SEK",
            symbol_first: false,
        },
        NOK : {
            code: "NOK",
            exponent: 2,
            locale: EnUs,
            minor_units: 100,
            name: "Norwegian Krone",
            // symbol: "kr",
            symbol: "NOK",
            symbol_first: false,
        },
        MEXICAN_PESO : {
            code: "USD",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "Mexican Peso",
            symbol: "MX$",
            symbol_first: true,
        },
        ZAR : {
            code: "ZAR",
            exponent: 2,
            locale: EnUs,
            minor_units: 10,
            name: "South African Rand",
            // symbol: "R",
            symbol: "ZAR",
            symbol_first: true,
        },
        DKK : {
            code: "DKK",
            exponent: 2,
            locale: EnEu,
            minor_units: 50,
            name: "Danish Krone",
            // symbol: "kr.",
            symbol: "DKK",
            symbol_first: false,
        },
        THB : {
            code: "THB",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "Thai Baht",
            // symbol: "฿",
            symbol: "THB",
            symbol_first: true,
        },
        HUF : {
            code: "HUF",
            exponent: 0,
            locale: EnBy,
            minor_units: 5,
            name: "Hungarian Forint",
            // symbol: "Ft",
            symbol: "HUF",
            symbol_first: false,
        },
        KORUNA : {
            code: "CZK",
            exponent: 2,
            locale: EnBy,
            minor_units: 100,
            name: "Czech Koruna",
            // symbol: "Kč",
            symbol: "CZK",
            symbol_first: false,
        },
        SHEKEL : {
            code: "CZK",
            exponent: 2,
            locale: EnBy,
            minor_units: 100,
            name: "Czech Koruna",
            symbol: "Kč",
            symbol_first: false,
        },
        CLP : {
            code: "CLP",
            exponent: 0,
            locale: EnEu,
            minor_units: 1,
            name: "Chilean Peso",
            // symbol: "$",
            symbol: "CLP",
            symbol_first: true,
        },
        PHP : {
            code: "PHP",
            exponent: 2,
            locale: EnUs,
            minor_units: 1,
            name: "Philippine Peso",
            symbol: "₱",
            symbol_first: true,
        },
        AED : {
            code: "AED",
            exponent: 2,
            locale: EnUs,
            minor_units: 25,
            name: "United Arab Emirates Dirham",
            // symbol: "د.إ",
            symbol: "AED",
            symbol_first: false,
        },
        COP : {
            code: "COP",
            exponent: 2,
            locale: EnEu,
            minor_units: 20,
            name: "Colombian Peso",
            // symbol: "$",
            symbol: "COP",
            symbol_first: true,
        },
        SAR : {
            code: "SAR",
            exponent: 2,
            locale: EnUs,
            minor_units: 5,
            name: "Saudi Riyal",
            // symbol: "ر.س",
            symbol: "SAR",
            symbol_first: true,
        },
        MYR : {
            code: "MYR",
            exponent: 2,
            locale: EnUs,
            minor_units: 5,
            name: "Malaysian Ringgit",
            // symbol: "RM",
            symbol: "MYR",
            symbol_first: true,
        },
        RON : {
            code: "RON",
            exponent: 2,
            locale: EnEu,
            minor_units: 1,
            name: "Romanian Leu",
            // symbol: "ر.ق",
            symbol: "RON",
            symbol_first: false,
        },
        ARS : {
            code: "ARS",
            exponent: 2,
            locale: EnEu,
            minor_units: 1,
            name: "Argentine Peso",
            // symbol: "$",
            symbol: "ARS",
            symbol_first: true,
        },
        UYU : {
            code: "UYU",
            exponent: 2,
            locale: EnEu,
            minor_units: 100,
            name: "Uruguayan Peso",
            // symbol: "$U",
            symbol: "UYU",
            symbol_first: true,
        }
    }
);

impl NumberFormat {
    pub fn currency(&self) -> &'static number_currency::Currency {
        match self {
            NumberFormat::Number => number_currency::NUMBER,
            NumberFormat::USD => number_currency::USD,
            NumberFormat::CanadianDollar => number_currency::CANADIAN_DOLLAR,
            NumberFormat::EUR => number_currency::EUR,
            NumberFormat::Pound => number_currency::GIP,
            NumberFormat::Yen => number_currency::CNY,
            NumberFormat::Ruble => number_currency::RUB,
            NumberFormat::Rupee => number_currency::INR,
            NumberFormat::Won => number_currency::KRW,
            NumberFormat::Yuan => number_currency::YUAN,
            NumberFormat::Real => number_currency::BRL,
            NumberFormat::Lira => number_currency::TRY,
            NumberFormat::Rupiah => number_currency::IDR,
            NumberFormat::Franc => number_currency::CHF,
            NumberFormat::HongKongDollar => number_currency::HONG_KONG_DOLLAR,
            NumberFormat::NewZealandDollar => number_currency::NEW_ZEALAND_DOLLAR,
            NumberFormat::Krona => number_currency::SEK,
            NumberFormat::NorwegianKrone => number_currency::NOK,
            NumberFormat::MexicanPeso => number_currency::MEXICAN_PESO,
            NumberFormat::Rand => number_currency::ZAR,
            NumberFormat::NewTaiwanDollar => number_currency::NEW_TAIWAN_DOLLAR,
            NumberFormat::DanishKrone => number_currency::DKK,
            NumberFormat::Baht => number_currency::THB,
            NumberFormat::Forint => number_currency::HUF,
            NumberFormat::Koruna => number_currency::KORUNA,
            NumberFormat::Shekel => number_currency::SHEKEL,
            NumberFormat::ChileanPeso => number_currency::CLP,
            NumberFormat::PhilippinePeso => number_currency::PHP,
            NumberFormat::Dirham => number_currency::AED,
            NumberFormat::ColombianPeso => number_currency::COP,
            NumberFormat::Riyal => number_currency::SAR,
            NumberFormat::Ringgit => number_currency::MYR,
            NumberFormat::Leu => number_currency::RON,
            NumberFormat::ArgentinePeso => number_currency::ARS,
            NumberFormat::UruguayanPeso => number_currency::UYU,
            NumberFormat::Percent => number_currency::USD,
        }
    }

    pub fn symbol(&self) -> String {
        self.currency().symbol.to_string()
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
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::entities::{FieldMeta, FieldType};
    use strum::IntoEnumIterator;

    #[test]
    fn number_description_invalid_input_test() {
        let type_option = NumberTypeOption::default();
        let field_type = FieldType::Number;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();
        assert_equal(&type_option, "", "", &field_type, &field_meta);
        assert_equal(&type_option, "abc", "", &field_type, &field_meta);
    }

    #[test]
    fn number_description_test() {
        let mut type_option = NumberTypeOption::default();
        let field_type = FieldType::Number;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();
        assert_eq!(type_option.strip_symbol("¥18,443"), "18443".to_owned());
        assert_eq!(type_option.strip_symbol("$18,443"), "18443".to_owned());
        assert_eq!(type_option.strip_symbol("€18.443"), "18443".to_owned());

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Number => {
                    assert_equal(&type_option, "18443", "18443", &field_type, &field_meta);
                }
                NumberFormat::USD => {
                    assert_equal(&type_option, "18443", "$18,443", &field_type, &field_meta);
                    assert_equal(&type_option, "", "", &field_type, &field_meta);
                    assert_equal(&type_option, "abc", "", &field_type, &field_meta);
                }
                NumberFormat::Yen => {
                    assert_equal(&type_option, "18443", "¥18,443", &field_type, &field_meta);
                }
                NumberFormat::Yuan => {
                    assert_equal(&type_option, "18443", "CN¥18,443", &field_type, &field_meta);
                }
                NumberFormat::EUR => {
                    assert_equal(&type_option, "18443", "€18.443", &field_type, &field_meta);
                }
                _ => {}
            }
        }
    }

    #[test]
    fn number_description_scale_test() {
        let mut type_option = NumberTypeOption {
            scale: 1,
            ..Default::default()
        };
        let field_type = FieldType::Number;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Number => {
                    assert_equal(&type_option, "18443", "18443", &field_type, &field_meta);
                }
                NumberFormat::USD => {
                    assert_equal(&type_option, "18443", "$1,844.3", &field_type, &field_meta);
                }
                NumberFormat::Yen => {
                    assert_equal(&type_option, "18443", "¥1,844.3", &field_type, &field_meta);
                }
                NumberFormat::EUR => {
                    assert_equal(&type_option, "18443", "€1.844,3", &field_type, &field_meta);
                }
                _ => {}
            }
        }
    }

    #[test]
    fn number_description_sign_test() {
        let mut type_option = NumberTypeOption {
            sign_positive: false,
            ..Default::default()
        };
        let field_type = FieldType::Number;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Number => {
                    assert_equal(&type_option, "18443", "18443", &field_type, &field_meta);
                }
                NumberFormat::USD => {
                    assert_equal(&type_option, "18443", "-$18,443", &field_type, &field_meta);
                }
                NumberFormat::Yen => {
                    assert_equal(&type_option, "18443", "-¥18,443", &field_type, &field_meta);
                }
                NumberFormat::EUR => {
                    assert_equal(&type_option, "18443", "-€18.443", &field_type, &field_meta);
                }
                _ => {}
            }
        }
    }

    fn assert_equal(
        type_option: &NumberTypeOption,
        cell_data: &str,
        expected_str: &str,
        field_type: &FieldType,
        field_meta: &FieldMeta,
    ) {
        assert_eq!(
            type_option
                .decode_cell_data(cell_data, field_type, field_meta)
                .unwrap()
                .to_string(),
            expected_str.to_owned()
        );
    }
}
