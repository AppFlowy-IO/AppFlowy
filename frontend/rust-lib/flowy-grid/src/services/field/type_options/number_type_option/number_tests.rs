#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::CellDataOperation;
    use crate::services::field::FieldBuilder;
    use crate::services::field::{strip_currency_symbol, NumberFormat, NumberTypeOptionPB};
    use flowy_grid_data_model::revision::FieldRevision;
    use strum::IntoEnumIterator;

    /// Testing when the input is not a number.
    #[test]
    fn number_type_option_invalid_input_test() {
        let type_option = NumberTypeOptionPB::default();
        let field_type = FieldType::Number;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        // Input is empty String
        assert_number(&type_option, "", "", &field_type, &field_rev);

        // Input is letter
        assert_number(&type_option, "abc", "", &field_type, &field_rev);
    }

    /// Testing the strip_currency_symbol function. It should return the string without the input symbol.
    #[test]
    fn number_type_option_strip_symbol_test() {
        // Remove the $ symbol
        assert_eq!(strip_currency_symbol("$18,443"), "18,443".to_owned());
        // Remove the ¥ symbol
        assert_eq!(strip_currency_symbol("¥0.2"), "0.2".to_owned());
    }

    /// Format the input number to the corresponding format string.
    #[test]
    fn number_type_option_format_number_test() {
        let mut type_option = NumberTypeOptionPB::default();
        let field_type = FieldType::Number;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Num => {
                    assert_number(&type_option, "18443", "18443", &field_type, &field_rev);
                }
                NumberFormat::USD => {
                    assert_number(&type_option, "18443", "$18,443", &field_type, &field_rev);
                }
                NumberFormat::Yen => {
                    assert_number(&type_option, "18443", "¥18,443", &field_type, &field_rev);
                }
                NumberFormat::Yuan => {
                    assert_number(&type_option, "18443", "CN¥18,443", &field_type, &field_rev);
                }
                NumberFormat::EUR => {
                    assert_number(&type_option, "18443", "€18.443", &field_type, &field_rev);
                }
                _ => {}
            }
        }
    }

    /// Format the input String to the corresponding format string.
    #[test]
    fn number_type_option_format_str_test() {
        let mut type_option = NumberTypeOptionPB::default();
        let field_type = FieldType::Number;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Num => {
                    assert_number(&type_option, "18443", "18443", &field_type, &field_rev);
                    assert_number(&type_option, "0.2", "0.2", &field_type, &field_rev);
                }
                NumberFormat::USD => {
                    assert_number(&type_option, "$18,44", "$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "$0.2", "$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "", "", &field_type, &field_rev);
                    assert_number(&type_option, "abc", "", &field_type, &field_rev);
                }
                NumberFormat::Yen => {
                    assert_number(&type_option, "¥18,44", "¥1,844", &field_type, &field_rev);
                    assert_number(&type_option, "¥1844", "¥1,844", &field_type, &field_rev);
                }
                NumberFormat::Yuan => {
                    assert_number(&type_option, "CN¥18,44", "CN¥1,844", &field_type, &field_rev);
                    assert_number(&type_option, "CN¥1844", "CN¥1,844", &field_type, &field_rev);
                }
                NumberFormat::EUR => {
                    assert_number(&type_option, "€18.44", "€18,44", &field_type, &field_rev);
                    assert_number(&type_option, "€0.5", "€0,5", &field_type, &field_rev);
                    assert_number(&type_option, "€1844", "€1.844", &field_type, &field_rev);
                }
                NumberFormat::Percent => {
                    assert_number(&type_option, "1", "1%", &field_type, &field_rev);
                    assert_number(&type_option, "10.1", "10.1%", &field_type, &field_rev);
                    assert_number(&type_option, "100", "100%", &field_type, &field_rev);
                }
                _ => {}
            }
        }
    }

    /// Carry out the sign positive to input number
    #[test]
    fn number_description_sign_test() {
        let mut type_option = NumberTypeOptionPB {
            sign_positive: false,
            ..Default::default()
        };
        let field_type = FieldType::Number;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();

        for format in NumberFormat::iter() {
            type_option.format = format;
            match format {
                NumberFormat::Num => {
                    assert_number(&type_option, "18443", "18443", &field_type, &field_rev);
                }
                NumberFormat::USD => {
                    assert_number(&type_option, "18443", "-$18,443", &field_type, &field_rev);
                }
                NumberFormat::Yen => {
                    assert_number(&type_option, "18443", "-¥18,443", &field_type, &field_rev);
                }
                NumberFormat::EUR => {
                    assert_number(&type_option, "18443", "-€18.443", &field_type, &field_rev);
                }
                _ => {}
            }
        }
    }

    fn assert_number(
        type_option: &NumberTypeOptionPB,
        input_str: &str,
        expected_str: &str,
        field_type: &FieldType,
        field_rev: &FieldRevision,
    ) {
        assert_eq!(
            type_option
                .decode_cell_data(input_str.to_owned().into(), field_type, field_rev)
                .unwrap()
                .to_string(),
            expected_str.to_owned()
        );
    }
}
