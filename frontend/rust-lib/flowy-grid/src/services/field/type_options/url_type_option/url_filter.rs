use crate::services::cell::{CellFilterable, TypeCellData};
use crate::services::field::{TypeOptionCellData, TypeOptionConfiguration, URLTypeOptionPB};
use flowy_error::FlowyResult;

impl CellFilterable for URLTypeOptionPB {
    fn apply_filter(
        &self,
        type_cell_data: TypeCellData,
        filter: &<Self as TypeOptionConfiguration>::CellFilterConfiguration,
    ) -> FlowyResult<bool> {
        if !type_cell_data.is_url() {
            return Ok(true);
        }

        let url_cell_data = self.decode_type_option_cell_data(type_cell_data.cell_data)?;
        Ok(filter.is_visible(&url_cell_data))
    }
}
