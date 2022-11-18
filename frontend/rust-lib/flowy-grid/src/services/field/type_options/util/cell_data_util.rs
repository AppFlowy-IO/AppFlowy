use crate::services::cell::TypeCellData;
use grid_rev_model::CellRevision;
use std::str::FromStr;

pub fn get_cell_data(cell_rev: &CellRevision) -> String {
    match TypeCellData::from_str(&cell_rev.data) {
        Ok(type_option) => type_option.data,
        Err(_) => String::new(),
    }
}
