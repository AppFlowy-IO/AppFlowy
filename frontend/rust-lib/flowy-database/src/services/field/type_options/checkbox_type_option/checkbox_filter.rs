use crate::entities::{CheckboxFilterConditionPB, CheckboxFilterPB};
use crate::services::field::CheckboxCellData;

impl CheckboxFilterPB {
    pub fn is_visible(&self, cell_data: &CheckboxCellData) -> bool {
        let is_check = cell_data.is_check();
        match self.condition {
            CheckboxFilterConditionPB::IsChecked => is_check,
            CheckboxFilterConditionPB::IsUnChecked => !is_check,
        }
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
