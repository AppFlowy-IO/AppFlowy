use crate::impl_type_option;
use crate::services::row::{CellDataSerde, TypeOptionCellData};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{FieldMeta, FieldType, TypeOptionDataEntity, TypeOptionDataEntry};
use lazy_static::lazy_static;

use rust_decimal::Decimal;
use rusty_money::iso::{Currency, CNY, EUR, USD};
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

impl CellDataSerde for NumberTypeOption {
    fn deserialize_cell_data(&self, data: String, _field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if type_option_cell_data.is_date() {
                return String::new();
            }

            let cell_data = type_option_cell_data.data;
            match self.format {
                NumberFormat::Number => {
                    if cell_data.parse::<i64>().is_ok() {
                        cell_data
                    } else {
                        String::new()
                    }
                }
                NumberFormat::USD => self.money_from_str(&cell_data, USD),
                NumberFormat::CNY => self.money_from_str(&cell_data, CNY),
                NumberFormat::EUR => self.money_from_str(&cell_data, EUR),
            }
        } else {
            String::new()
        }
    }

    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError> {
        let data = self.strip_symbol(data);

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

    fn strip_symbol(&self, s: &str) -> String {
        let mut s = String::from(s);
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
    use crate::services::row::{CellDataSerde, TypeOptionCellData};
    use flowy_grid_data_model::entities::FieldType;
    use strum::IntoEnumIterator;

    #[test]
    fn number_description_invalid_input_test() {
        let type_option = NumberTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::Number).build();
        assert_eq!("".to_owned(), type_option.deserialize_cell_data(data(""), &field_meta));
        assert_eq!(
            "".to_owned(),
            type_option.deserialize_cell_data(data("abc"), &field_meta)
        );
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
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "18443".to_owned()
                    );
                }
                NumberFormat::USD => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "$18,443".to_owned()
                    );
                    assert_eq!(type_option.deserialize_cell_data(data(""), &field_meta), "".to_owned());
                    assert_eq!(
                        type_option.deserialize_cell_data(data("abc"), &field_meta),
                        "".to_owned()
                    );
                }
                NumberFormat::CNY => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "¥18,443".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
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
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "18443".to_owned()
                    );
                }
                NumberFormat::USD => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "$1,844.3".to_owned()
                    );
                }
                NumberFormat::CNY => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "¥1,844.3".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
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
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "18443".to_owned()
                    );
                }
                NumberFormat::USD => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "-$18,443".to_owned()
                    );
                }
                NumberFormat::CNY => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "-¥18,443".to_owned()
                    );
                }
                NumberFormat::EUR => {
                    assert_eq!(
                        type_option.deserialize_cell_data(data("18443"), &field_meta),
                        "-€18.443".to_owned()
                    );
                }
            }
        }
    }
}
