use crate::services::row::AnyCellData;
use flowy_grid_data_model::revision::CellRevision;
use std::str::FromStr;

pub fn get_cell_data(cell_rev: &CellRevision) -> String {
    match AnyCellData::from_str(&cell_rev.data) {
        Ok(type_option) => type_option.cell_data,
        Err(_) => String::new(),
    }
}
