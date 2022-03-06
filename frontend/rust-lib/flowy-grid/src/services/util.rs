use crate::services::cell_data::FlowyMoney;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{AnyData, Field, FieldType};
use lazy_static::lazy_static;
use rust_decimal::Decimal;
use rusty_money::{iso::Currency, Money};
use std::collections::HashMap;
use std::str::FromStr;
use strum::IntoEnumIterator;

lazy_static! {
    static ref CURRENCIES_BY_SYMBOL: HashMap<String, &'static Currency> = generate_currency_by_symbol();
}

#[allow(dead_code)]
fn generate_currency_by_symbol() -> HashMap<String, &'static Currency> {
    let mut map: HashMap<String, &'static Currency> = HashMap::new();

    for money in FlowyMoney::iter() {
        map.insert(money.symbol(), money.currency());
    }
    map
}

#[allow(dead_code)]
pub fn string_to_money(money_str: &str) -> Option<Money<Currency>> {
    let mut process_money_str = String::from(money_str);
    let default_currency = FlowyMoney::from_symbol_str("CNY").currency();

    if process_money_str.is_empty() {
        return None;
    }

    return if process_money_str.chars().all(char::is_numeric) {
        match Money::from_str(&process_money_str, default_currency) {
            Ok(money) => Some(money),
            Err(_) => None,
        }
    } else {
        let symbol = process_money_str.chars().next().unwrap().to_string();
        let mut currency = default_currency;

        for key in CURRENCIES_BY_SYMBOL.keys() {
            if symbol.eq(key) {
                currency = CURRENCIES_BY_SYMBOL.get(key).unwrap();
                crop_letters(&mut process_money_str, 1);
            }
        }

        match Money::from_str(&process_money_str, currency) {
            Ok(money) => Some(money),
            Err(_) => None,
        }
    };
}

#[allow(dead_code)]
pub fn money_from_str(s: &str) -> Option<String> {
    match Decimal::from_str(s) {
        Ok(mut decimal) => {
            match decimal.set_scale(0) {
                Ok(_) => {}
                Err(e) => {
                    tracing::error!("Set scale failed. {:?}", e);
                }
            }
            decimal.set_sign_positive(true);
            Some(FlowyMoney::USD.with_decimal(decimal).to_string())
        }
        Err(e) => {
            tracing::debug!("Format {} to money failed, {:?}", s, e);
            None
        }
    }
}

pub fn strip_money_symbol(money_str: &str) -> String {
    let mut process_money_str = String::from(money_str);

    if !process_money_str.chars().all(char::is_numeric) {
        let symbol = process_money_str.chars().next().unwrap().to_string();
        for key in CURRENCIES_BY_SYMBOL.keys() {
            if symbol.eq(key) {
                crop_letters(&mut process_money_str, 1);
            }
        }
    }
    process_money_str
}

fn crop_letters(s: &mut String, pos: usize) {
    match s.char_indices().nth(pos) {
        Some((pos, _)) => {
            s.drain(..pos);
        }
        None => {
            s.clear();
        }
    }
}

pub fn string_to_bool(bool_str: &str) -> bool {
    let lower_case_str: &str = &bool_str.to_lowercase();
    match lower_case_str {
        "1" => true,
        "true" => true,
        "yes" => true,
        "0" => false,
        "false" => false,
        "no" => false,
        _ => false,
    }
}

pub fn uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}

pub fn check_type_id(data: &AnyData, field: &Field) -> Result<(), FlowyError> {
    let field_type = FieldType::from_type_id(&data.type_id).map_err(|e| FlowyError::internal().context(e))?;
    if field_type != field.field_type {
        tracing::error!(
            "expected field type: {:?} but receive {:?} ",
            field_type,
            field.field_type
        );
    }
    Ok(())
}
