use crate::entities::TextFilterPB;
use crate::services::cell::{CellFilterable, IntoCellData, TypeCellData};
use crate::services::field::{TextCellData, URLTypeOptionPB};
use flowy_error::FlowyResult;

impl CellFilterable<TextFilterPB> for URLTypeOptionPB {
    fn apply_filter(&self, type_cell_data: TypeCellData, filter: &TextFilterPB) -> FlowyResult<bool> {
        if !type_cell_data.is_url() {
            return Ok(true);
        }

        let cell_data: IntoCellData<TextCellData> = type_cell_data.into();
        let text_cell_data = cell_data.try_into_inner()?;
        Ok(filter.is_visible(&text_cell_data))
    }
}
