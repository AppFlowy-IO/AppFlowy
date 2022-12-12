use crate::entities::{CheckboxFilterConditionPB, CheckboxFilterPB};
use crate::services::cell::{CellData, CellFilterOperation, TypeCellData};
use crate::services::field::{CheckboxCellData, CheckboxTypeOptionPB};
use flowy_error::FlowyResult;

impl CheckboxFilterPB {
    pub fn is_visible(&self, cell_data: &CheckboxCellData) -> bool {
        let is_check = cell_data.is_check();
        match self.condition {
            CheckboxFilterConditionPB::IsChecked => is_check,
            CheckboxFilterConditionPB::IsUnChecked => !is_check,
        }
    }
}

impl CellFilterOperation<CheckboxFilterPB> for CheckboxTypeOptionPB {
    fn apply_filter(&self, any_cell_data: TypeCellData, filter: &CheckboxFilterPB) -> FlowyResult<bool> {
        if !any_cell_data.is_checkbox() {
            return Ok(true);
        }
        let cell_data: CellData<CheckboxCellData> = any_cell_data.into();
        let checkbox_cell_data = cell_data.try_into_inner()?;
        Ok(filter.is_visible(&checkbox_cell_data))
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::{CheckboxFilterConditionPB, CheckboxFilterPB};
    use crate::services::field::CheckboxCellData;
    use std::str::FromStr;

    #[test]
    fn checkbox_filter_is_check_test() {
        let checkbox_filter = CheckboxFilterPB {
            condition: CheckboxFilterConditionPB::IsChecked,
        };
        for (value, visible) in [("true", true), ("yes", true), ("false", false), ("no", false)] {
            let data = CheckboxCellData::from_str(value).unwrap();
            assert_eq!(checkbox_filter.is_visible(&data), visible);
        }
    }

    #[test]
    fn checkbox_filter_is_uncheck_test() {
        let checkbox_filter = CheckboxFilterPB {
            condition: CheckboxFilterConditionPB::IsUnChecked,
        };
        for (value, visible) in [("false", true), ("no", true), ("true", false), ("yes", false)] {
            let data = CheckboxCellData::from_str(value).unwrap();
            assert_eq!(checkbox_filter.is_visible(&data), visible);
        }
    }
}
