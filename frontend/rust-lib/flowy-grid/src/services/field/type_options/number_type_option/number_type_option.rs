use crate::impl_type_option;

use crate::services::field::type_options::number_type_option::format::*;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellContentChangeset, CellDataOperation, DecodedCellData};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
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
                let content = self.number_from_str(&cell_data);
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

    fn number_from_str(&self, s: &str) -> String {
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
            Err(_) => {
                let s = self.strip_symbol(s);
                if !s.is_empty() && s.chars().all(char::is_numeric) {
                    self.number_from_str(&s)
                } else {
                    "".to_owned()
                }
            }
        }
    }

    fn strip_symbol<T: ToString>(&self, s: T) -> String {
        let mut s = s.to_string();

        for symbol in CURRENCY_SYMBOL.iter() {
            if s.starts_with(symbol) {
                s = s.strip_prefix(symbol).unwrap_or("").to_string();
                break;
            }
        }

        if !s.chars().all(char::is_numeric) {
            s.retain(|c| !STRIP_SYMBOL.contains(&c.to_string()));
        }
        s
    }
}

#[cfg(test)]
mod tests {
    use crate::services::field::FieldBuilder;
    use crate::services::field::{NumberFormat, NumberTypeOption};
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::entities::{FieldMeta, FieldType};
    use strum::IntoEnumIterator;

    #[test]
    fn number_type_option_invalid_input_test() {
        let type_option = NumberTypeOption::default();
        let field_type = FieldType::Number;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();
        assert_equal(&type_option, "", "", &field_type, &field_meta);
        assert_equal(&type_option, "abc", "", &field_type, &field_meta);
    }

    #[test]
    fn number_type_option_format_number_test() {
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
    fn number_type_option_format_str_test() {
        let mut type_option = NumberTypeOption::default();
        let field_type = FieldType::Number;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Number => {
                    // assert_equal(&type_option, "18443", "18443", &field_type, &field_meta);
                }
                NumberFormat::USD => {
                    assert_equal(&type_option, "$18,44", "$1,844", &field_type, &field_meta);
                    assert_equal(&type_option, "", "", &field_type, &field_meta);
                    assert_equal(&type_option, "abc", "", &field_type, &field_meta);
                }
                NumberFormat::Yen => {
                    assert_equal(&type_option, "¥18,44", "¥1,844", &field_type, &field_meta);
                    assert_equal(&type_option, "¥1844", "¥1,844", &field_type, &field_meta);
                }
                NumberFormat::Yuan => {
                    assert_equal(&type_option, "CN¥18,44", "CN¥1,844", &field_type, &field_meta);
                    assert_equal(&type_option, "CN¥1844", "CN¥1,844", &field_type, &field_meta);
                }
                NumberFormat::EUR => {
                    assert_equal(&type_option, "€18.44", "€1.844", &field_type, &field_meta);
                    assert_equal(&type_option, "€1844", "€1.844", &field_type, &field_meta);
                }
                _ => {}
            }
        }
    }

    #[test]
    fn number_type_option_scale_test() {
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
