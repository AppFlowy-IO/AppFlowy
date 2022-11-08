use crate::services::cell::AnyCellData;
use grid_rev_model::CellRevision;
use std::str::FromStr;

pub fn get_cell_data(cell_rev: &CellRevision) -> String {
    match AnyCellData::from_str(&cell_rev.data) {
        Ok(type_option) => type_option.data,
        Err(_) => String::new(),
    }
}
