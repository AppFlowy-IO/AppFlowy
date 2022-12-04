#![allow(clippy::needless_collect)]

use crate::entities::{ChecklistFilterPB, FieldType, SelectOptionCondition, SelectOptionFilterPB};
use crate::services::cell::{CellFilterOperation, TypeCellData};
use crate::services::field::{ChecklistTypeOptionPB, MultiSelectTypeOptionPB, SingleSelectTypeOptionPB};
use crate::services::field::{SelectTypeOptionSharedAction, SelectedSelectOptions};
use flowy_error::FlowyResult;

impl SelectOptionFilterPB {
    pub fn is_visible(&self, selected_options: &SelectedSelectOptions, field_type: FieldType) -> bool {
        let selected_option_ids: Vec<&String> = selected_options.options.iter().map(|option| &option.id).collect();
        match self.condition {
            SelectOptionCondition::OptionIs => match field_type {
                FieldType::SingleSelect => {
                    if self.option_ids.is_empty() && selected_options.options.is_empty() {
                        return true;
                    }

                    if selected_options.options.is_empty() {
                        return false;
                    }

                    let first_selected_option_id = self.option_ids.first().unwrap();
                    let first_selected_option = selected_options.options.first().unwrap();
                    &first_selected_option.id == first_selected_option_id
                }
                FieldType::MultiSelect => {
                    let required_options = self
                        .option_ids
                        .iter()
                        .filter(|id| selected_option_ids.contains(id))
                        .collect::<Vec<_>>();

                    // if the len of the required_options equal to the len of the cell selected options,
                    // which means the current cell is visible.
                    required_options.len() == self.option_ids.len()
                }
                _ => false,
            },
            SelectOptionCondition::OptionIsNot => match field_type {
                FieldType::SingleSelect => {
                    if self.option_ids.is_empty() && !selected_options.options.is_empty() {
                        return true;
                    }

                    if selected_options.options.is_empty() {
                        return true;
                    }

                    let first_selected_option_id = self.option_ids.first().unwrap();
                    let first_selected_option = selected_options.options.first().unwrap();
                    &first_selected_option.id != first_selected_option_id
                }
                FieldType::MultiSelect => {
                    let required_options = self
                        .option_ids
                        .iter()
                        .filter(|id| selected_option_ids.contains(id))
                        .collect::<Vec<_>>();

                    required_options.is_empty()
                }
                _ => false,
            },
            SelectOptionCondition::OptionIsEmpty => selected_option_ids.is_empty(),
            SelectOptionCondition::OptionIsNotEmpty => !selected_option_ids.is_empty(),
        }
    }
}

impl CellFilterOperation<SelectOptionFilterPB> for MultiSelectTypeOptionPB {
    fn apply_filter(&self, any_cell_data: TypeCellData, filter: &SelectOptionFilterPB) -> FlowyResult<bool> {
        if !any_cell_data.is_multi_select() {
            return Ok(true);
        }

        let selected_options = SelectedSelectOptions::from(self.get_selected_options(any_cell_data.into()));
        Ok(filter.is_visible(&selected_options, FieldType::MultiSelect))
    }
}

impl CellFilterOperation<SelectOptionFilterPB> for SingleSelectTypeOptionPB {
    fn apply_filter(&self, any_cell_data: TypeCellData, filter: &SelectOptionFilterPB) -> FlowyResult<bool> {
        if !any_cell_data.is_single_select() {
            return Ok(true);
        }
        let selected_options = SelectedSelectOptions::from(self.get_selected_options(any_cell_data.into()));
        Ok(filter.is_visible(&selected_options, FieldType::SingleSelect))
    }
}

impl CellFilterOperation<ChecklistFilterPB> for ChecklistTypeOptionPB {
    fn apply_filter(&self, any_cell_data: TypeCellData, filter: &ChecklistFilterPB) -> FlowyResult<bool> {
        if !any_cell_data.is_checklist() {
            return Ok(true);
        }
        let selected_options = SelectedSelectOptions::from(self.get_selected_options(any_cell_data.into()));
        Ok(filter.is_visible(&self.options, &selected_options))
    }
}

#[cfg(test)]
mod tests {
    #![allow(clippy::all)]
    use crate::entities::{FieldType, SelectOptionCondition, SelectOptionFilterPB};
    use crate::services::field::selection_type_option::{SelectOptionPB, SelectedSelectOptions};

    #[test]
    fn select_option_filter_is_empty_test() {
        let option = SelectOptionPB::new("A");
        let filter = SelectOptionFilterPB {
            condition: SelectOptionCondition::OptionIsEmpty,
            option_ids: vec![],
        };

        assert_eq!(
            filter.is_visible(&SelectedSelectOptions { options: vec![] }, FieldType::SingleSelect),
            true
        );
        assert_eq!(
            filter.is_visible(
                &SelectedSelectOptions {
                    options: vec![option.clone()]
                },
                FieldType::SingleSelect
            ),
            false,
        );

        assert_eq!(
            filter.is_visible(&SelectedSelectOptions { options: vec![] }, FieldType::MultiSelect),
            true
        );
        assert_eq!(
            filter.is_visible(&SelectedSelectOptions { options: vec![option] }, FieldType::MultiSelect),
            false,
        );
    }

    #[test]
    fn select_option_filter_is_not_empty_test() {
        let option_1 = SelectOptionPB::new("A");
        let option_2 = SelectOptionPB::new("B");
        let filter = SelectOptionFilterPB {
            condition: SelectOptionCondition::OptionIsNotEmpty,
            option_ids: vec![option_1.id.clone(), option_2.id.clone()],
        };

        assert_eq!(
            filter.is_visible(
                &SelectedSelectOptions {
                    options: vec![option_1.clone()]
                },
                FieldType::SingleSelect
            ),
            true
        );
        assert_eq!(
            filter.is_visible(&SelectedSelectOptions { options: vec![] }, FieldType::SingleSelect),
            false,
        );

        assert_eq!(
            filter.is_visible(
                &SelectedSelectOptions {
                    options: vec![option_1.clone()]
                },
                FieldType::MultiSelect
            ),
            true
        );
        assert_eq!(
            filter.is_visible(&SelectedSelectOptions { options: vec![] }, FieldType::MultiSelect),
            false,
        );
    }

    #[test]
    fn single_select_option_filter_is_not_test() {
        let option_1 = SelectOptionPB::new("A");
        let option_2 = SelectOptionPB::new("B");
        let filter = SelectOptionFilterPB {
            condition: SelectOptionCondition::OptionIsNot,
            option_ids: vec![option_1.id.clone(), option_2.id.clone()],
        };

        for (options, is_visible) in vec![
            // In single select, only compare the first option
            (vec![option_2.clone()], true),
            (vec![option_1.clone()], false),
            (vec![option_1.clone(), option_2.clone()], false),
        ] {
            assert_eq!(
                filter.is_visible(&SelectedSelectOptions { options }, FieldType::SingleSelect),
                is_visible
            );
        }
    }

    #[test]
    fn multi_select_option_filter_not_contains_test() {
        let option_1 = SelectOptionPB::new("A");
        let option_2 = SelectOptionPB::new("B");
        let option_3 = SelectOptionPB::new("C");
        let filter = SelectOptionFilterPB {
            condition: SelectOptionCondition::OptionIsNot,
            option_ids: vec![option_1.id.clone(), option_2.id.clone()],
        };

        for (options, is_visible) in vec![
            (vec![option_1.clone(), option_2.clone()], false),
            (vec![option_1.clone()], false),
            (vec![option_2.clone()], false),
            (vec![option_3.clone()], true),
            (vec![option_1.clone(), option_2.clone(), option_3.clone()], false),
            (vec![], true),
        ] {
            assert_eq!(
                filter.is_visible(&SelectedSelectOptions { options }, FieldType::MultiSelect),
                is_visible
            );
        }
    }

    #[test]
    fn single_select_option_filter_is_test() {
        let option_1 = SelectOptionPB::new("A");
        let option_2 = SelectOptionPB::new("B");

        let filter = SelectOptionFilterPB {
            condition: SelectOptionCondition::OptionIs,
            option_ids: vec![option_1.id.clone(), option_2.id.clone()],
        };
        for (options, is_visible) in vec![
            (vec![option_1.clone()], true),
            // In single select, only compare the first option
            (vec![option_1.clone(), option_2.clone()], true),
            (vec![option_2.clone(), option_1.clone()], false),
        ] {
            assert_eq!(
                filter.is_visible(&SelectedSelectOptions { options }, FieldType::SingleSelect),
                is_visible
            );
        }

        let filter = SelectOptionFilterPB {
            condition: SelectOptionCondition::OptionIs,
            option_ids: vec![option_1.id.clone()],
        };
        for (options, is_visible) in vec![
            (vec![option_1.clone()], true),
            // In single select, only compare the first option
            (vec![option_1.clone(), option_2.clone()], true),
            (vec![option_2.clone(), option_1.clone()], false),
        ] {
            assert_eq!(
                filter.is_visible(&SelectedSelectOptions { options }, FieldType::SingleSelect),
                is_visible
            );
        }
    }

    #[test]
    fn multi_select_option_filter_contains_test() {
        let option_1 = SelectOptionPB::new("A");
        let option_2 = SelectOptionPB::new("B");
        let option_3 = SelectOptionPB::new("C");

        let filter = SelectOptionFilterPB {
            condition: SelectOptionCondition::OptionIs,
            option_ids: vec![option_1.id.clone(), option_2.id.clone()],
        };
        for (options, is_visible) in vec![
            (vec![option_1.clone(), option_2.clone(), option_3.clone()], true),
            (vec![option_2.clone(), option_1.clone()], true),
            (vec![option_2.clone()], false),
            (vec![option_1.clone(), option_3.clone()], false),
        ] {
            assert_eq!(
                filter.is_visible(&SelectedSelectOptions { options }, FieldType::MultiSelect),
                is_visible
            );
        }
    }
}
