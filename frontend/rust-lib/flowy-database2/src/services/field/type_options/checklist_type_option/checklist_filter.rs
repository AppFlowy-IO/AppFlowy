use collab_database::fields::select_type_option::SelectOption;
use collab_database::fields::Field;
use collab_database::rows::Cell;

use crate::entities::{ChecklistFilterConditionPB, ChecklistFilterPB};
use crate::services::filter::PreFillCellsWithFilter;

impl ChecklistFilterPB {
  pub fn is_visible(
    &self,
    all_options: &[SelectOption],
    selected_options: &[SelectOption],
  ) -> bool {
    let selected_option_ids = selected_options
      .iter()
      .map(|option| option.id.as_str())
      .collect::<Vec<&str>>();

    let mut all_option_ids = all_options
      .iter()
      .map(|option| option.id.as_str())
      .collect::<Vec<&str>>();

    match self.condition {
      ChecklistFilterConditionPB::IsComplete => {
        if selected_option_ids.is_empty() {
          return false;
        }

        all_option_ids.retain(|option_id| !selected_option_ids.contains(option_id));
        all_option_ids.is_empty()
      },
      ChecklistFilterConditionPB::IsIncomplete => {
        if selected_option_ids.is_empty() {
          return true;
        }

        all_option_ids.retain(|option_id| !selected_option_ids.contains(option_id));
        !all_option_ids.is_empty()
      },
    }
  }
}

impl PreFillCellsWithFilter for ChecklistFilterPB {
  fn get_compliant_cell(&self, _field: &Field) -> Option<Cell> {
    None
  }
}
