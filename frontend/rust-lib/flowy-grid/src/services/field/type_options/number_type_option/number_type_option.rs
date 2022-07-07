use crate::impl_type_option;

use crate::entities::{FieldType, GridNumberFilter};
use crate::services::field::number_currency::Currency;
use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{
    AnyCellData, CellContentChangeset, CellDataOperation, CellFilterOperation, DecodedCellData,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataEntry};
use rust_decimal::prelude::Zero;
use rust_decimal::{Decimal, Error};
use rusty_money::Money;
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

    fn format_cell_data(&self, s: &str) -> FlowyResult<NumberCellData> {
        match self.format {
            NumberFormat::Num | NumberFormat::Percent => match Decimal::from_str(s) {
                Ok(value, ..) => Ok(NumberCellData::from_decimal(value)),
                Err(_) => Ok(NumberCellData::new()),
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
impl CellFilterOperation<GridNumberFilter> for NumberTypeOption {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &GridNumberFilter) -> FlowyResult<bool> {
        let cell_data = any_cell_data.cell_data;
        let num_cell_data = self.format_cell_data(&cell_data)?;

        Ok(filter.apply(&num_cell_data))
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
        match self.format_cell_data(&cell_data) {
            Ok(num) => Ok(DecodedCellData::new(num.to_string())),
            Err(_) => Ok(DecodedCellData::default()),
        }
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_rev: Option<CellRevision>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let changeset = changeset.into();
        let data = changeset.trim().to_string();
        let _ = self.format_cell_data(&data)?;
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
                        Err(FlowyError::invalid_data().context("Should only contain numbers"))
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
            decimal: Some(money.amount().clone()),
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

impl FromStr for NumberCellData {
    type Err = rust_decimal::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s.is_empty() {
            return Ok(Self::default());
        }
        let decimal = Decimal::from_str(s)?;
        Ok(Self::from_decimal(decimal))
    }
}

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

#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::field::FieldBuilder;
    use crate::services::field::{strip_currency_symbol, NumberFormat, NumberTypeOption};
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
        assert_eq!(strip_currency_symbol("$18,443"), "18,443".to_owned());

        type_option.format = NumberFormat::Yuan;
        assert_eq!(strip_currency_symbol("$0.2"), "0.2".to_owned());
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
