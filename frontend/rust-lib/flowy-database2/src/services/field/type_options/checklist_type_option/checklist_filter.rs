use crate::entities::ChecklistCellDataChangesetPB;
use crate::entities::{ChecklistFilterConditionPB, ChecklistFilterPB};
use crate::services::filter::PreFillCellsWithFilter;

use collab_database::fields::select_type_option::SelectOption;
use collab_database::fields::Field;
use collab_database::rows::Cell;
use collab_database::template::check_list_parse::ChecklistCellData;

use std::fmt::Debug;

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

pub fn checklist_from_options(new_tasks: Vec<ChecklistCellInsertChangeset>) -> ChecklistCellData {
  let (options, selected_ids): (Vec<_>, Vec<_>) = new_tasks
    .into_iter()
    .map(|new_task| {
      let option = SelectOption::new(&new_task.name);
      let selected_id = new_task.is_complete.then(|| option.id.clone());
      (option, selected_id)
    })
    .unzip();
  let selected_option_ids = selected_ids.into_iter().flatten().collect();

  ChecklistCellData {
    options,
    selected_option_ids,
  }
}

#[derive(Debug, Clone, Default)]
pub struct ChecklistCellChangeset {
  pub insert_tasks: Vec<ChecklistCellInsertChangeset>,
  pub delete_tasks: Vec<String>,
  pub update_tasks: Vec<SelectOption>,
  pub completed_task_ids: Vec<String>,
  pub reorder: String,
}

impl From<ChecklistCellDataChangesetPB> for ChecklistCellChangeset {
  fn from(value: ChecklistCellDataChangesetPB) -> Self {
    ChecklistCellChangeset {
      insert_tasks: value
        .insert_task
        .into_iter()
        .map(|pb| ChecklistCellInsertChangeset {
          name: pb.name,
          is_complete: false,
          index: pb.index,
        })
        .collect(),
      delete_tasks: value.delete_tasks,
      update_tasks: value
        .update_tasks
        .into_iter()
        .map(SelectOption::from)
        .collect(),
      completed_task_ids: value.completed_tasks,
      reorder: value.reorder,
    }
  }
}

#[derive(Debug, Clone, Default)]
pub struct ChecklistCellInsertChangeset {
  pub name: String,
  pub is_complete: bool,
  pub index: Option<i32>,
}

impl ChecklistCellInsertChangeset {
  pub fn new(name: String, is_complete: bool) -> Self {
    Self {
      name,
      is_complete,
      index: None,
    }
  }
}

#[cfg(test)]
mod tests {
  #[test]
  fn test() {
    let a = 1;
    let b = 2;

    let c = (a as f32) / (b as f32);
    println!("{}", c);
  }
}
