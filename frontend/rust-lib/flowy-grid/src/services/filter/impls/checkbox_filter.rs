use crate::entities::{CheckboxCondition, CheckboxFilterConfigurationPB};
use crate::services::cell::{AnyCellData, CellData, CellFilterOperation};
use crate::services::field::{CheckboxCellData, CheckboxTypeOptionPB};
use flowy_error::FlowyResult;

impl CheckboxFilterConfigurationPB {
    pub fn is_visible(&self, cell_data: &CheckboxCellData) -> bool {
        let is_check = cell_data.is_check();
        match self.condition {
            CheckboxCondition::IsChecked => is_check,
            CheckboxCondition::IsUnChecked => !is_check,
        }
    }
}

impl CellFilterOperation<CheckboxFilterConfigurationPB> for CheckboxTypeOptionPB {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &CheckboxFilterConfigurationPB) -> FlowyResult<bool> {
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
    use crate::entities::{CheckboxCondition, CheckboxFilterConfigurationPB};
    use crate::services::field::CheckboxCellData;
    use std::str::FromStr;

    #[test]
    fn checkbox_filter_is_check_test() {
        let checkbox_filter = CheckboxFilterConfigurationPB {
            condition: CheckboxCondition::IsChecked,
        };
        for (value, visible) in [("true", true), ("yes", true), ("false", false), ("no", false)] {
            let data = CheckboxCellData::from_str(value).unwrap();
            assert_eq!(checkbox_filter.is_visible(&data), visible);
        }
    }

    #[test]
    fn checkbox_filter_is_uncheck_test() {
        let checkbox_filter = CheckboxFilterConfigurationPB {
            condition: CheckboxCondition::IsUnChecked,
        };
        for (value, visible) in [("false", true), ("no", true), ("true", false), ("yes", false)] {
            let data = CheckboxCellData::from_str(value).unwrap();
            assert_eq!(checkbox_filter.is_visible(&data), visible);
        }
    }
}
