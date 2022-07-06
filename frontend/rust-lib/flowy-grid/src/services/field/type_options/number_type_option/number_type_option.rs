use crate::impl_type_option;

use crate::entities::{FieldType, GridNumberFilter};
use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{
    AnyCellData, CellContentChangeset, CellDataOperation, CellFilterOperation, DecodedCellData,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataEntry};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

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
        FieldType::Number
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

impl NumberTypeOption {
    pub fn new() -> Self {
        Self::default()
    }

    fn cell_content_from_number_str(&self, s: &str) -> FlowyResult<String> {
        match self.format {
            NumberFormat::Num => {
                if let Ok(v) = s.parse::<f64>() {
                    return Ok(v.to_string());
                }

                if let Ok(v) = s.parse::<i64>() {
                    return Ok(v.to_string());
                }

                Ok("".to_string())
            }
            NumberFormat::Percent => {
                let content = s.parse::<f64>().map_or(String::new(), |v| v.to_string());
                Ok(content)
            }
            _ => self.money_from_number_str(s),
        }
    }

    pub fn set_format(&mut self, format: NumberFormat) {
        self.format = format;
        self.symbol = format.symbol();
    }

    fn money_from_number_str(&self, s: &str) -> FlowyResult<String> {
        let mut number = self.strip_currency_symbol(s);

        if s.is_empty() {
            return Ok("".to_string());
        }

        match Decimal::from_str(&number) {
            Ok(mut decimal) => {
                decimal.set_sign_positive(self.sign_positive);
                let money = rusty_money::Money::from_decimal(decimal, self.format.currency()).to_string();
                Ok(money)
            }
            Err(_) => match rusty_money::Money::from_str(&number, self.format.currency()) {
                Ok(money) => Ok(money.to_string()),
                Err(_) => {
                    number.retain(|c| !STRIP_SYMBOL.contains(&c.to_string()));
                    if number.chars().all(char::is_numeric) {
                        self.money_from_number_str(&number)
                    } else {
                        Err(FlowyError::invalid_data().context("Should only contain numbers"))
                    }
                }
            },
        }
    }

    fn strip_currency_symbol<T: ToString>(&self, s: T) -> String {
        let mut s = s.to_string();
        for symbol in CURRENCY_SYMBOL.iter() {
            if s.starts_with(symbol) {
                s = s.strip_prefix(symbol).unwrap_or("").to_string();
                break;
            }
        }
        s
    }
}
impl CellFilterOperation<GridNumberFilter, AnyCellData> for NumberTypeOption {
    fn apply_filter(&self, any_cell_data: AnyCellData, _filter: &GridNumberFilter) -> bool {
        let _number_cell_data = NumberCellData::from_number_type_option(self, any_cell_data);
        false
    }
}

impl CellDataOperation<String> for NumberTypeOption {
    fn decode_cell_data<T>(
        &self,
        cell_data: T,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<String>,
    {
        if decoded_field_type.is_date() {
            return Ok(DecodedCellData::default());
        }

        let cell_data = cell_data.into();
        match self.format {
            NumberFormat::Num => {
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
                let content = self
                    .money_from_number_str(&cell_data)
                    .unwrap_or_else(|_| "".to_string());
                Ok(DecodedCellData::new(content))
            }
        }
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_rev: Option<CellRevision>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let changeset = changeset.into();
        let data = changeset.trim().to_string();
        let _ = self.cell_content_from_number_str(&data)?;
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

#[derive(Default)]
pub struct NumberCellData(String);

impl NumberCellData {
    fn from_number_type_option(type_option: &NumberTypeOption, any_cell_data: AnyCellData) -> Self {
        let cell_data = any_cell_data.cell_data;
        match type_option.format {
            NumberFormat::Num => {
                if let Ok(v) = cell_data.parse::<f64>() {
                    return Self(v.to_string());
                }

                if let Ok(v) = cell_data.parse::<i64>() {
                    return Self(v.to_string());
                }

                Self::default()
            }
            NumberFormat::Percent => {
                let content = cell_data.parse::<f64>().map_or(String::new(), |v| v.to_string());
                Self(content)
            }
            _ => {
                let content = type_option
                    .money_from_number_str(&cell_data)
                    .unwrap_or_else(|_| "".to_string());
                Self(content)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::field::FieldBuilder;
    use crate::services::field::{NumberFormat, NumberTypeOption};
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::revision::FieldRevision;
    use strum::IntoEnumIterator;

    #[test]
    fn number_type_option_invalid_input_test() {
        let type_option = NumberTypeOption::default();
        let field_type = FieldType::Number;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_equal(&type_option, "", "", &field_type, &field_rev);
        assert_equal(&type_option, "abc", "", &field_type, &field_rev);
    }

    #[test]
    fn number_type_option_strip_symbol_test() {
        let mut type_option = NumberTypeOption::new();
        type_option.format = NumberFormat::USD;
        assert_eq!(type_option.strip_currency_symbol("$18,443"), "18,443".to_owned());

        type_option.format = NumberFormat::Yuan;
        assert_eq!(type_option.strip_currency_symbol("$0.2"), "0.2".to_owned());
    }

    #[test]
    fn number_type_option_format_number_test() {
        let mut type_option = NumberTypeOption::default();
        let field_type = FieldType::Number;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Num => {
                    assert_equal(&type_option, "18443", "18443", &field_type, &field_rev);
                }
                NumberFormat::USD => {
                    assert_equal(&type_option, "18443", "$18,443", &field_type, &field_rev);
                }
                NumberFormat::Yen => {
                    assert_equal(&type_option, "18443", "¥18,443", &field_type, &field_rev);
                }
                NumberFormat::Yuan => {
                    assert_equal(&type_option, "18443", "CN¥18,443", &field_type, &field_rev);
                }
                NumberFormat::EUR => {
                    assert_equal(&type_option, "18443", "€18.443", &field_type, &field_rev);
                }
                _ => {}
            }
        }
    }

    #[test]
    fn number_type_option_format_str_test() {
        let mut type_option = NumberTypeOption::default();
        let field_type = FieldType::Number;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Num => {
                    assert_equal(&type_option, "18443", "18443", &field_type, &field_rev);
                    assert_equal(&type_option, "0.2", "0.2", &field_type, &field_rev);
                }
                NumberFormat::USD => {
                    assert_equal(&type_option, "$18,44", "$1,844", &field_type, &field_rev);
                    assert_equal(&type_option, "$0.2", "$0.2", &field_type, &field_rev);
                    assert_equal(&type_option, "", "", &field_type, &field_rev);
                    assert_equal(&type_option, "abc", "", &field_type, &field_rev);
                }
                NumberFormat::Yen => {
                    assert_equal(&type_option, "¥18,44", "¥1,844", &field_type, &field_rev);
                    assert_equal(&type_option, "¥1844", "¥1,844", &field_type, &field_rev);
                }
                NumberFormat::Yuan => {
                    assert_equal(&type_option, "CN¥18,44", "CN¥1,844", &field_type, &field_rev);
                    assert_equal(&type_option, "CN¥1844", "CN¥1,844", &field_type, &field_rev);
                }
                NumberFormat::EUR => {
                    assert_equal(&type_option, "€18.44", "€18,44", &field_type, &field_rev);
                    assert_equal(&type_option, "€0.5", "€0,5", &field_type, &field_rev);
                    assert_equal(&type_option, "€1844", "€1.844", &field_type, &field_rev);
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
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Num => {
                    assert_equal(&type_option, "18443", "18443", &field_type, &field_rev);
                }
                NumberFormat::USD => {
                    assert_equal(&type_option, "18443", "-$18,443", &field_type, &field_rev);
                }
                NumberFormat::Yen => {
                    assert_equal(&type_option, "18443", "-¥18,443", &field_type, &field_rev);
                }
                NumberFormat::EUR => {
                    assert_equal(&type_option, "18443", "-€18.443", &field_type, &field_rev);
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
        field_rev: &FieldRevision,
    ) {
        assert_eq!(
            type_option
                .decode_cell_data(cell_data, field_type, field_rev)
                .unwrap()
                .to_string(),
            expected_str.to_owned()
        );
    }
}
