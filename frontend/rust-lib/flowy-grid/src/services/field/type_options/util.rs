use crate::services::row::TypeOptionCellData;
use flowy_grid_data_model::entities::CellMeta;
use std::str::FromStr;

pub fn get_cell_data(cell_meta: &CellMeta) -> String {
    match TypeOptionCellData::from_str(&cell_meta.data) {
        Ok(type_option) => type_option.data,
        Err(_) => String::new(),
    }
}
