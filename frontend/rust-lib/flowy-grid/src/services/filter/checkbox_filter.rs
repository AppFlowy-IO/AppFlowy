use crate::entities::{CheckboxCondition, GridCheckboxFilter};
use crate::services::field::CheckboxCellData;

impl GridCheckboxFilter {
    pub fn apply(&self, cell_data: &CheckboxCellData) -> bool {
        let is_check = cell_data.is_check();
        match self.condition {
            CheckboxCondition::IsChecked => is_check,
            CheckboxCondition::IsUnChecked => !is_check,
        }
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
}
