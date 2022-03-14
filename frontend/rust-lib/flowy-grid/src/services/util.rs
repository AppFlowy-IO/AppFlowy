//
// #[allow(dead_code)]
// pub fn string_to_money(money_str: &str) -> Option<Money<Currency>> {
//     let mut process_money_str = String::from(money_str);
//     let default_currency = MoneySymbol::from_symbol_str("CNY").currency();
//
//     if process_money_str.is_empty() {
//         return None;
//     }
//
//     return if process_money_str.chars().all(char::is_numeric) {
//         match Money::from_str(&process_money_str, default_currency) {
//             Ok(money) => Some(money),
//             Err(_) => None,
//         }
//     } else {
//         let symbol = process_money_str.chars().next().unwrap().to_string();
//         let mut currency = default_currency;
//
//         for key in CURRENCIES_BY_SYMBOL.keys() {
//             if symbol.eq(key) {
//                 currency = CURRENCIES_BY_SYMBOL.get(key).unwrap();
//                 crop_letters(&mut process_money_str, 1);
//             }
//         }
//
//         match Money::from_str(&process_money_str, currency) {
//             Ok(money) => Some(money),
//             Err(_) => None,
//         }
//     };
// }

pub fn uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}
