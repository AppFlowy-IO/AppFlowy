use crate::entities::ChecklistFilterPB;
use crate::services::field::SelectedSelectOptions;

impl ChecklistFilterPB {
    pub fn is_visible(&self, selected_options: &SelectedSelectOptions) -> bool {
        true
    }
}
