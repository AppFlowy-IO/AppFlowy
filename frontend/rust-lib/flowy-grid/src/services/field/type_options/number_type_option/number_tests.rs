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
                NumberFormat::CanadianDollar => {
                    assert_number(&type_option, "18443", "CA$18,443", &field_type, &field_rev)
                }
                NumberFormat::EUR => assert_number(&type_option, "18443", "€18.443", &field_type, &field_rev),
                NumberFormat::Pound => assert_number(&type_option, "18443", "£18,443", &field_type, &field_rev),

                NumberFormat::Yen => {
                    assert_number(&type_option, "18443", "¥18,443", &field_type, &field_rev);
                }
                NumberFormat::Ruble => assert_number(&type_option, "18443", "18.443RUB", &field_type, &field_rev),
                NumberFormat::Rupee => assert_number(&type_option, "18443", "₹18,443", &field_type, &field_rev),
                NumberFormat::Won => assert_number(&type_option, "18443", "₩18,443", &field_type, &field_rev),

                NumberFormat::Yuan => {
                    assert_number(&type_option, "18443", "CN¥18,443", &field_type, &field_rev);
                }
                NumberFormat::Real => {
                    assert_number(&type_option, "18443", "R$18,443", &field_type, &field_rev);
                }
                NumberFormat::Lira => assert_number(&type_option, "18443", "TRY18.443", &field_type, &field_rev),
                NumberFormat::Rupiah => assert_number(&type_option, "18443", "IDR18,443", &field_type, &field_rev),
                NumberFormat::Franc => assert_number(&type_option, "18443", "CHF18,443", &field_type, &field_rev),
                NumberFormat::HongKongDollar => {
                    assert_number(&type_option, "18443", "HZ$18,443", &field_type, &field_rev)
                }
                NumberFormat::NewZealandDollar => {
                    assert_number(&type_option, "18443", "NZ$18,443", &field_type, &field_rev)
                }
                NumberFormat::Krona => assert_number(&type_option, "18443", "18 443SEK", &field_type, &field_rev),
                NumberFormat::NorwegianKrone => {
                    assert_number(&type_option, "18443", "18,443NOK", &field_type, &field_rev)
                }
                NumberFormat::MexicanPeso => assert_number(&type_option, "18443", "MX$18,443", &field_type, &field_rev),
                NumberFormat::Rand => assert_number(&type_option, "18443", "ZAR18,443", &field_type, &field_rev),
                NumberFormat::NewTaiwanDollar => {
                    assert_number(&type_option, "18443", "NT$18,443", &field_type, &field_rev)
                }
                NumberFormat::DanishKrone => assert_number(&type_option, "18443", "18.443DKK", &field_type, &field_rev),
                NumberFormat::Baht => assert_number(&type_option, "18443", "THB18,443", &field_type, &field_rev),
                NumberFormat::Forint => assert_number(&type_option, "18443", "18 443HUF", &field_type, &field_rev),
                NumberFormat::Koruna => assert_number(&type_option, "18443", "18 443CZK", &field_type, &field_rev),
                NumberFormat::Shekel => assert_number(&type_option, "18443", "18 443Kč", &field_type, &field_rev),
                NumberFormat::ChileanPeso => assert_number(&type_option, "18443", "CLP18.443", &field_type, &field_rev),
                NumberFormat::PhilippinePeso => {
                    assert_number(&type_option, "18443", "₱18,443", &field_type, &field_rev)
                }
                NumberFormat::Dirham => assert_number(&type_option, "18443", "18,443AED", &field_type, &field_rev),
                NumberFormat::ColombianPeso => {
                    assert_number(&type_option, "18443", "COP18.443", &field_type, &field_rev)
                }
                NumberFormat::Riyal => assert_number(&type_option, "18443", "SAR18,443", &field_type, &field_rev),
                NumberFormat::Ringgit => assert_number(&type_option, "18443", "MYR18,443", &field_type, &field_rev),
                NumberFormat::Leu => assert_number(&type_option, "18443", "18.443RON", &field_type, &field_rev),
                NumberFormat::ArgentinePeso => {
                    assert_number(&type_option, "18443", "ARS18.443", &field_type, &field_rev)
                }
                NumberFormat::UruguayanPeso => {
                    assert_number(&type_option, "18443", "UYU18.443", &field_type, &field_rev)
                }
                NumberFormat::Percent => assert_number(&type_option, "18443", "18,443%", &field_type, &field_rev),
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
                    assert_number(&type_option, "", "", &field_type, &field_rev);
                    assert_number(&type_option, "abc", "", &field_type, &field_rev);
                }
                NumberFormat::USD => {
                    assert_number(&type_option, "$18,44", "$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "$0.2", "$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "$1844", "$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "$1,844", &field_type, &field_rev);
                }
                NumberFormat::CanadianDollar => {
                    assert_number(&type_option, "CA$18,44", "CA$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "CA$0.2", "CA$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "CA$1844", "CA$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "CA$1,844", &field_type, &field_rev);
                }
                NumberFormat::EUR => {
                    assert_number(&type_option, "€18.44", "€18,44", &field_type, &field_rev);
                    assert_number(&type_option, "€0.5", "€0,5", &field_type, &field_rev);
                    assert_number(&type_option, "€1844", "€1.844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "€1.844", &field_type, &field_rev);
                }
                NumberFormat::Pound => {
                    assert_number(&type_option, "£18,44", "£1,844", &field_type, &field_rev);
                    assert_number(&type_option, "£0.2", "£0.2", &field_type, &field_rev);
                    assert_number(&type_option, "£1844", "£1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "£1,844", &field_type, &field_rev);
                }
                NumberFormat::Yen => {
                    assert_number(&type_option, "¥18,44", "¥1,844", &field_type, &field_rev);
                    assert_number(&type_option, "¥0.2", "¥0.2", &field_type, &field_rev);
                    assert_number(&type_option, "¥1844", "¥1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "¥1,844", &field_type, &field_rev);
                }
                NumberFormat::Ruble => {
                    assert_number(&type_option, "RUB18.44", "18,44RUB", &field_type, &field_rev);
                    assert_number(&type_option, "0.5", "0,5RUB", &field_type, &field_rev);
                    assert_number(&type_option, "RUB1844", "1.844RUB", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1.844RUB", &field_type, &field_rev);
                }
                NumberFormat::Rupee => {
                    assert_number(&type_option, "₹18,44", "₹1,844", &field_type, &field_rev);
                    assert_number(&type_option, "₹0.2", "₹0.2", &field_type, &field_rev);
                    assert_number(&type_option, "₹1844", "₹1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "₹1,844", &field_type, &field_rev);
                }
                NumberFormat::Won => {
                    assert_number(&type_option, "₩18,44", "₩1,844", &field_type, &field_rev);
                    assert_number(&type_option, "₩0.3", "₩0", &field_type, &field_rev);
                    assert_number(&type_option, "₩1844", "₩1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "₩1,844", &field_type, &field_rev);
                }
                NumberFormat::Yuan => {
                    assert_number(&type_option, "CN¥18,44", "CN¥1,844", &field_type, &field_rev);
                    assert_number(&type_option, "CN¥0.2", "CN¥0.2", &field_type, &field_rev);
                    assert_number(&type_option, "CN¥1844", "CN¥1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "CN¥1,844", &field_type, &field_rev);
                }
                NumberFormat::Real => {
                    assert_number(&type_option, "R$18,44", "R$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "R$0.2", "R$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "R$1844", "R$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "R$1,844", &field_type, &field_rev);
                }
                NumberFormat::Lira => {
                    assert_number(&type_option, "TRY18.44", "TRY18,44", &field_type, &field_rev);
                    assert_number(&type_option, "TRY0.5", "TRY0,5", &field_type, &field_rev);
                    assert_number(&type_option, "TRY1844", "TRY1.844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "TRY1.844", &field_type, &field_rev);
                }
                NumberFormat::Rupiah => {
                    assert_number(&type_option, "IDR18,44", "IDR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "IDR0.2", "IDR0.2", &field_type, &field_rev);
                    assert_number(&type_option, "IDR1844", "IDR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "IDR1,844", &field_type, &field_rev);
                }
                NumberFormat::Franc => {
                    assert_number(&type_option, "CHF18,44", "CHF1,844", &field_type, &field_rev);
                    assert_number(&type_option, "CHF0.2", "CHF0.2", &field_type, &field_rev);
                    assert_number(&type_option, "CHF1844", "CHF1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "CHF1,844", &field_type, &field_rev);
                }
                NumberFormat::HongKongDollar => {
                    assert_number(&type_option, "HZ$18,44", "HZ$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "HZ$0.2", "HZ$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "HZ$1844", "HZ$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "HZ$1,844", &field_type, &field_rev);
                }
                NumberFormat::NewZealandDollar => {
                    assert_number(&type_option, "NZ$18,44", "NZ$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "NZ$0.2", "NZ$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "NZ$1844", "NZ$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "NZ$1,844", &field_type, &field_rev);
                }
                NumberFormat::Krona => {
                    assert_number(&type_option, "SEK18,44", "18,44SEK", &field_type, &field_rev);
                    assert_number(&type_option, "SEK0.2", "0,2SEK", &field_type, &field_rev);
                    assert_number(&type_option, "SEK1844", "1 844SEK", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1 844SEK", &field_type, &field_rev);
                }
                NumberFormat::NorwegianKrone => {
                    assert_number(&type_option, "NOK18,44", "1,844NOK", &field_type, &field_rev);
                    assert_number(&type_option, "NOK0.2", "0.2NOK", &field_type, &field_rev);
                    assert_number(&type_option, "NOK1844", "1,844NOK", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1,844NOK", &field_type, &field_rev);
                }
                NumberFormat::MexicanPeso => {
                    assert_number(&type_option, "MX$18,44", "MX$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "MX$0.2", "MX$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "MX$1844", "MX$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "MX$1,844", &field_type, &field_rev);
                }
                NumberFormat::Rand => {
                    assert_number(&type_option, "ZAR18,44", "ZAR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "ZAR0.2", "ZAR0.2", &field_type, &field_rev);
                    assert_number(&type_option, "ZAR1844", "ZAR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "ZAR1,844", &field_type, &field_rev);
                }
                NumberFormat::NewTaiwanDollar => {
                    assert_number(&type_option, "NT$18,44", "NT$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "NT$0.2", "NT$0.2", &field_type, &field_rev);
                    assert_number(&type_option, "NT$1844", "NT$1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "NT$1,844", &field_type, &field_rev);
                }
                NumberFormat::DanishKrone => {
                    assert_number(&type_option, "DKK18.44", "18,44DKK", &field_type, &field_rev);
                    assert_number(&type_option, "DKK0.5", "0,5DKK", &field_type, &field_rev);
                    assert_number(&type_option, "DKK1844", "1.844DKK", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1.844DKK", &field_type, &field_rev);
                }
                NumberFormat::Baht => {
                    assert_number(&type_option, "THB18,44", "THB1,844", &field_type, &field_rev);
                    assert_number(&type_option, "THB0.2", "THB0.2", &field_type, &field_rev);
                    assert_number(&type_option, "THB1844", "THB1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "THB1,844", &field_type, &field_rev);
                }
                NumberFormat::Forint => {
                    assert_number(&type_option, "HUF18,44", "18HUF", &field_type, &field_rev);
                    assert_number(&type_option, "HUF0.3", "0HUF", &field_type, &field_rev);
                    assert_number(&type_option, "HUF1844", "1 844HUF", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1 844HUF", &field_type, &field_rev);
                }
                NumberFormat::Koruna => {
                    assert_number(&type_option, "CZK18,44", "18,44CZK", &field_type, &field_rev);
                    assert_number(&type_option, "CZK0.2", "0,2CZK", &field_type, &field_rev);
                    assert_number(&type_option, "CZK1844", "1 844CZK", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1 844CZK", &field_type, &field_rev);
                }
                NumberFormat::Shekel => {
                    assert_number(&type_option, "Kč18,44", "18,44Kč", &field_type, &field_rev);
                    assert_number(&type_option, "Kč0.2", "0,2Kč", &field_type, &field_rev);
                    assert_number(&type_option, "Kč1844", "1 844Kč", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1 844Kč", &field_type, &field_rev);
                }
                NumberFormat::ChileanPeso => {
                    assert_number(&type_option, "CLP18.44", "CLP18", &field_type, &field_rev);
                    assert_number(&type_option, "0.5", "CLP0", &field_type, &field_rev);
                    assert_number(&type_option, "CLP1844", "CLP1.844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "CLP1.844", &field_type, &field_rev);
                }
                NumberFormat::PhilippinePeso => {
                    assert_number(&type_option, "₱18,44", "₱1,844", &field_type, &field_rev);
                    assert_number(&type_option, "₱0.2", "₱0.2", &field_type, &field_rev);
                    assert_number(&type_option, "₱1844", "₱1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "₱1,844", &field_type, &field_rev);
                }
                NumberFormat::Dirham => {
                    assert_number(&type_option, "AED18,44", "1,844AED", &field_type, &field_rev);
                    assert_number(&type_option, "AED0.2", "0.2AED", &field_type, &field_rev);
                    assert_number(&type_option, "AED1844", "1,844AED", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1,844AED", &field_type, &field_rev);
                }
                NumberFormat::ColombianPeso => {
                    assert_number(&type_option, "COP18.44", "COP18,44", &field_type, &field_rev);
                    assert_number(&type_option, "0.5", "COP0,5", &field_type, &field_rev);
                    assert_number(&type_option, "COP1844", "COP1.844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "COP1.844", &field_type, &field_rev);
                }
                NumberFormat::Riyal => {
                    assert_number(&type_option, "SAR18,44", "SAR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "SAR0.2", "SAR0.2", &field_type, &field_rev);
                    assert_number(&type_option, "SAR1844", "SAR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "SAR1,844", &field_type, &field_rev);
                }

                NumberFormat::Ringgit => {
                    assert_number(&type_option, "MYR18,44", "MYR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "MYR0.2", "MYR0.2", &field_type, &field_rev);
                    assert_number(&type_option, "MYR1844", "MYR1,844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "MYR1,844", &field_type, &field_rev);
                }
                NumberFormat::Leu => {
                    assert_number(&type_option, "RON18.44", "18,44RON", &field_type, &field_rev);
                    assert_number(&type_option, "0.5", "0,5RON", &field_type, &field_rev);
                    assert_number(&type_option, "RON1844", "1.844RON", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "1.844RON", &field_type, &field_rev);
                }
                NumberFormat::ArgentinePeso => {
                    assert_number(&type_option, "ARS18.44", "ARS18,44", &field_type, &field_rev);
                    assert_number(&type_option, "0.5", "ARS0,5", &field_type, &field_rev);
                    assert_number(&type_option, "ARS1844", "ARS1.844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "ARS1.844", &field_type, &field_rev);
                }
                NumberFormat::UruguayanPeso => {
                    assert_number(&type_option, "UYU18.44", "UYU18,44", &field_type, &field_rev);
                    assert_number(&type_option, "0.5", "UYU0,5", &field_type, &field_rev);
                    assert_number(&type_option, "UYU1844", "UYU1.844", &field_type, &field_rev);
                    assert_number(&type_option, "1844", "UYU1.844", &field_type, &field_rev);
                }
                NumberFormat::Percent => {
                    assert_number(&type_option, "1", "1%", &field_type, &field_rev);
                    assert_number(&type_option, "10.1", "10.1%", &field_type, &field_rev);
                    assert_number(&type_option, "100", "100%", &field_type, &field_rev);
                }
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
                NumberFormat::CanadianDollar => {
                    assert_number(&type_option, "18443", "-CA$18,443", &field_type, &field_rev)
                }
                NumberFormat::EUR => assert_number(&type_option, "18443", "-€18.443", &field_type, &field_rev),
                NumberFormat::Pound => assert_number(&type_option, "18443", "-£18,443", &field_type, &field_rev),

                NumberFormat::Yen => {
                    assert_number(&type_option, "18443", "-¥18,443", &field_type, &field_rev);
                }
                NumberFormat::Ruble => assert_number(&type_option, "18443", "-18.443RUB", &field_type, &field_rev),
                NumberFormat::Rupee => assert_number(&type_option, "18443", "-₹18,443", &field_type, &field_rev),
                NumberFormat::Won => assert_number(&type_option, "18443", "-₩18,443", &field_type, &field_rev),

                NumberFormat::Yuan => {
                    assert_number(&type_option, "18443", "-CN¥18,443", &field_type, &field_rev);
                }
                NumberFormat::Real => {
                    assert_number(&type_option, "18443", "-R$18,443", &field_type, &field_rev);
                }
                NumberFormat::Lira => assert_number(&type_option, "18443", "-TRY18.443", &field_type, &field_rev),
                NumberFormat::Rupiah => assert_number(&type_option, "18443", "-IDR18,443", &field_type, &field_rev),
                NumberFormat::Franc => assert_number(&type_option, "18443", "-CHF18,443", &field_type, &field_rev),
                NumberFormat::HongKongDollar => {
                    assert_number(&type_option, "18443", "-HZ$18,443", &field_type, &field_rev)
                }
                NumberFormat::NewZealandDollar => {
                    assert_number(&type_option, "18443", "-NZ$18,443", &field_type, &field_rev)
                }
                NumberFormat::Krona => assert_number(&type_option, "18443", "-18 443SEK", &field_type, &field_rev),
                NumberFormat::NorwegianKrone => {
                    assert_number(&type_option, "18443", "-18,443NOK", &field_type, &field_rev)
                }
                NumberFormat::MexicanPeso => {
                    assert_number(&type_option, "18443", "-MX$18,443", &field_type, &field_rev)
                }
                NumberFormat::Rand => assert_number(&type_option, "18443", "-ZAR18,443", &field_type, &field_rev),
                NumberFormat::NewTaiwanDollar => {
                    assert_number(&type_option, "18443", "-NT$18,443", &field_type, &field_rev)
                }
                NumberFormat::DanishKrone => {
                    assert_number(&type_option, "18443", "-18.443DKK", &field_type, &field_rev)
                }
                NumberFormat::Baht => assert_number(&type_option, "18443", "-THB18,443", &field_type, &field_rev),
                NumberFormat::Forint => assert_number(&type_option, "18443", "-18 443HUF", &field_type, &field_rev),
                NumberFormat::Koruna => assert_number(&type_option, "18443", "-18 443CZK", &field_type, &field_rev),
                NumberFormat::Shekel => assert_number(&type_option, "18443", "-18 443Kč", &field_type, &field_rev),
                NumberFormat::ChileanPeso => {
                    assert_number(&type_option, "18443", "-CLP18.443", &field_type, &field_rev)
                }
                NumberFormat::PhilippinePeso => {
                    assert_number(&type_option, "18443", "-₱18,443", &field_type, &field_rev)
                }
                NumberFormat::Dirham => assert_number(&type_option, "18443", "-18,443AED", &field_type, &field_rev),
                NumberFormat::ColombianPeso => {
                    assert_number(&type_option, "18443", "-COP18.443", &field_type, &field_rev)
                }
                NumberFormat::Riyal => assert_number(&type_option, "18443", "-SAR18,443", &field_type, &field_rev),
                NumberFormat::Ringgit => assert_number(&type_option, "18443", "-MYR18,443", &field_type, &field_rev),
                NumberFormat::Leu => assert_number(&type_option, "18443", "-18.443RON", &field_type, &field_rev),
                NumberFormat::ArgentinePeso => {
                    assert_number(&type_option, "18443", "-ARS18.443", &field_type, &field_rev)
                }
                NumberFormat::UruguayanPeso => {
                    assert_number(&type_option, "18443", "-UYU18.443", &field_type, &field_rev)
                }
                NumberFormat::Percent => assert_number(&type_option, "18443", "-18,443%", &field_type, &field_rev),
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
