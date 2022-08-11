#![allow(clippy::needless_collect)]

use crate::entities::{GridSelectOptionFilter, SelectOptionCondition};
use crate::services::cell::{AnyCellData, CellFilterOperation};
use crate::services::field::{MultiSelectTypeOptionPB, SingleSelectTypeOptionPB};
use crate::services::field::{SelectOptionOperation, SelectedSelectOptions};
use flowy_error::FlowyResult;

impl GridSelectOptionFilter {
    pub fn is_visible(&self, selected_options: &SelectedSelectOptions) -> bool {
        let selected_option_ids: Vec<&String> = selected_options.options.iter().map(|option| &option.id).collect();
        match self.condition {
            SelectOptionCondition::OptionIs => {
                if self.option_ids.len() != selected_option_ids.len() {
                    return true;
                }

                // if selected options equal to filter's options, then the required_options will be empty.
                let required_options = self
                    .option_ids
                    .iter()
                    .filter(|id| !selected_option_ids.contains(id))
                    .collect::<Vec<_>>();

                // https://stackoverflow.com/questions/69413164/how-to-fix-this-clippy-warning-needless-collect
                !required_options.is_empty()
            }
            SelectOptionCondition::OptionIsNot => {
                for option_id in selected_option_ids {
                    if self.option_ids.contains(option_id) {
                        return true;
                    }
                }
                false
            }
            SelectOptionCondition::OptionIsEmpty => selected_option_ids.is_empty(),
            SelectOptionCondition::OptionIsNotEmpty => !selected_option_ids.is_empty(),
        }
    }
}

impl CellFilterOperation<GridSelectOptionFilter> for MultiSelectTypeOptionPB {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &GridSelectOptionFilter) -> FlowyResult<bool> {
        if !any_cell_data.is_multi_select() {
            return Ok(true);
        }

        let selected_options = SelectedSelectOptions::from(self.selected_select_option(any_cell_data.into()));
        Ok(filter.is_visible(&selected_options))
    }
}

impl CellFilterOperation<GridSelectOptionFilter> for SingleSelectTypeOptionPB {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &GridSelectOptionFilter) -> FlowyResult<bool> {
        if !any_cell_data.is_single_select() {
            return Ok(true);
        }
        let selected_options = SelectedSelectOptions::from(self.selected_select_option(any_cell_data.into()));
        Ok(filter.is_visible(&selected_options))
    }
}

#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::entities::{GridSelectOptionFilter, SelectOptionCondition};
    use crate::services::field::selection_type_option::{SelectOptionPB, SelectedSelectOptions};

    #[test]
    fn select_option_filter_is_test() {
        let option_1 = SelectOptionPB::new("A");
        let option_2 = SelectOptionPB::new("B");
        let option_3 = SelectOptionPB::new("C");

        let filter_1 = GridSelectOptionFilter {
            condition: SelectOptionCondition::OptionIs,
            option_ids: vec![option_1.id.clone(), option_2.id.clone()],
        };

        assert_eq!(
            filter_1.is_visible(&SelectedSelectOptions {
                options: vec![option_1.clone(), option_2.clone()],
            }),
            false
        );

        assert_eq!(
            filter_1.is_visible(&SelectedSelectOptions {
                options: vec![option_1.clone(), option_2.clone(), option_3.clone()],
            }),
            true
        );

        assert_eq!(
            filter_1.is_visible(&SelectedSelectOptions {
                options: vec![option_1.clone(), option_3.clone()],
            }),
            true
        );

        assert_eq!(filter_1.is_visible(&SelectedSelectOptions { options: vec![] }), true);
        assert_eq!(
            filter_1.is_visible(&SelectedSelectOptions {
                options: vec![option_1.clone()],
            }),
            true,
        );
    }
}
