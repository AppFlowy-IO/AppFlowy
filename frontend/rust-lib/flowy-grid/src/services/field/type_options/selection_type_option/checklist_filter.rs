use crate::entities::{ChecklistFilterCondition, ChecklistFilterPB};
use crate::services::field::{SelectOptionPB, SelectedSelectOptions};

impl ChecklistFilterPB {
    pub fn is_visible(&self, all_options: &[SelectOptionPB], selected_options: &SelectedSelectOptions) -> bool {
        let selected_option_ids = selected_options
            .options
            .iter()
            .map(|option| option.id.as_str())
            .collect::<Vec<&str>>();

        let mut all_option_ids = all_options
            .iter()
            .map(|option| option.id.as_str())
            .collect::<Vec<&str>>();

        match self.condition {
            ChecklistFilterCondition::IsComplete => {
                if selected_option_ids.is_empty() {
                    return false;
                }

                all_option_ids.retain(|option_id| !selected_option_ids.contains(option_id));
                all_option_ids.is_empty()
            }
            ChecklistFilterCondition::IsIncomplete => {
                if selected_option_ids.is_empty() {
                    return true;
                }

                all_option_ids.retain(|option_id| !selected_option_ids.contains(option_id));
                !all_option_ids.is_empty()
            }
        }
    }
}
