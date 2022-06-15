use crate::services::row::TypeOptionCellData;
use flowy_grid_data_model::revision::CellRevision;
use std::str::FromStr;

pub fn get_cell_data(cell_rev: &CellRevision) -> String {
    match TypeOptionCellData::from_str(&cell_rev.data) {
        Ok(type_option) => type_option.data,
        Err(_) => String::new(),
    }
}
