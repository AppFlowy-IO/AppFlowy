use crate::entities::{CheckboxCondition, GridCheckboxFilter};
use crate::services::cell::{AnyCellData, CellFilterOperation};
use crate::services::field::{CheckboxCellData, CheckboxTypeOption};
use flowy_error::FlowyResult;

impl GridCheckboxFilter {
    pub fn apply(&self, cell_data: &CheckboxCellData) -> bool {
        let is_check = cell_data.is_check();
        match self.condition {
            CheckboxCondition::IsChecked => is_check,
            CheckboxCondition::IsUnChecked => !is_check,
        }
    }
}

impl CellFilterOperation<GridCheckboxFilter> for CheckboxTypeOption {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &GridCheckboxFilter) -> FlowyResult<bool> {
        if !any_cell_data.is_checkbox() {
            return Ok(true);
        }
        let checkbox_cell_data: CheckboxCellData = any_cell_data.try_into()?;
        Ok(filter.apply(&checkbox_cell_data))
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::{CheckboxCondition, GridCheckboxFilter};
    use crate::services::field::CheckboxCellData;

    #[test]
    fn checkbox_filter_is_check_test() {
        let checkbox_filter = GridCheckboxFilter {
            condition: CheckboxCondition::IsChecked,
        };
        for (value, r) in [("true", true), ("yes", true), ("false", false), ("no", false)] {
            let data = CheckboxCellData(value.to_owned());
            assert_eq!(checkbox_filter.apply(&data), r);
        }
    }

    #[test]
    fn checkbox_filter_is_uncheck_test() {
        let checkbox_filter = GridCheckboxFilter {
            condition: CheckboxCondition::IsUnChecked,
        };
        for (value, r) in [("false", true), ("no", true), ("true", false), ("yes", false)] {
            let data = CheckboxCellData(value.to_owned());
            assert_eq!(checkbox_filter.apply(&data), r);
        }
    }
}
