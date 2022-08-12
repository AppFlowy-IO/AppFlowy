use crate::entities::{
    CheckboxGroupConfigurationPB, DateGroupConfigurationPB, NumberGroupConfigurationPB,
    SelectOptionGroupConfigurationPB, TextGroupConfigurationPB, UrlGroupConfigurationPB,
};
use crate::services::cell::CellBytes;
use crate::services::field::{
    CheckboxCellDataParser, DateCellDataParser, NumberCellDataParser, NumberFormat, SelectOptionCellDataParser,
    TextCellDataParser, URLCellDataParser,
};
use crate::services::group::GroupAction;

// impl GroupAction for TextGroupConfigurationPB {
//     fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool {
//         if let Ok(cell_data) = cell_bytes.with_parser(TextCellDataParser()) {
//             cell_data.as_ref() == content
//         } else {
//             false
//         }
//     }
// }
//
// impl GroupAction for NumberGroupConfigurationPB {
//     fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool {
//         if let Ok(cell_data) = cell_bytes.with_parser(NumberCellDataParser(NumberFormat::Num)) {
//             false
//         } else {
//             false
//         }
//     }
// }
//
// impl GroupAction for DateGroupConfigurationPB {
//     fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool {
//         if let Ok(cell_data) = cell_bytes.with_parser(DateCellDataParser()) {
//             false
//         } else {
//             false
//         }
//     }
// }
//
// impl GroupAction for SelectOptionGroupConfigurationPB {
//     fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool {
//         if let Ok(cell_data) = cell_bytes.with_parser(SelectOptionCellDataParser()) {
//             false
//         } else {
//             false
//         }
//     }
// }
//
// impl GroupAction for UrlGroupConfigurationPB {
//     fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool {
//         if let Ok(cell_data) = cell_bytes.with_parser(URLCellDataParser()) {
//             false
//         } else {
//             false
//         }
//     }
// }
//
// impl GroupAction for CheckboxGroupConfigurationPB {
//     fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool {
//         if let Ok(cell_data) = cell_bytes.with_parser(CheckboxCellDataParser()) {
//             false
//         } else {
//             false
//         }
//     }
// }
