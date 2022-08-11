use crate::entities::SelectOptionGroupConfigurationPB;
use crate::services::field::SelectedSelectOptions;

impl SelectOptionGroupConfigurationPB {
    pub fn is_visible(&self, selected_options: &SelectedSelectOptions) -> bool {
        return true;
    }
}
