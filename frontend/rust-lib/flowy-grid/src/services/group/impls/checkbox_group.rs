use crate::entities::CheckboxGroupConfigurationPB;
use crate::services::cell::{AnyCellData, CellData, CellGroupOperation};
use crate::services::field::{CheckboxCellData, CheckboxTypeOption};
use flowy_error::FlowyResult;

impl CellGroupOperation for CheckboxTypeOption {
    fn apply_group(&self, any_cell_data: AnyCellData, content: &str) -> FlowyResult<bool> {
        if !any_cell_data.is_checkbox() {
            return Ok(true);
        }
        let cell_data: CellData<CheckboxCellData> = any_cell_data.into();
        let checkbox_cell_data = cell_data.try_into_inner()?;

        // Ok(checkbox_cell_data.as_ref() == content)
        todo!()
    }
}
