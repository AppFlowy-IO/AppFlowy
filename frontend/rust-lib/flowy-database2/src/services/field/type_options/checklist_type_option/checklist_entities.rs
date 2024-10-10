use crate::entities::{ChecklistCellDataChangesetPB, FieldType};
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::util::AnyMapExt;
use collab_database::fields::select_type_option::SelectOption;
use collab_database::rows::{new_cell_builder, Cell};
use serde::{Deserialize, Serialize};
use std::fmt::Debug;

#[derive(Default, Clone, Debug, Serialize, Deserialize)]
pub struct ChecklistCellData {
  pub options: Vec<SelectOption>,
  pub selected_option_ids: Vec<String>,
}

impl ToString for ChecklistCellData {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap_or_default()
  }
}

impl TypeOptionCellData for ChecklistCellData {
  fn is_cell_empty(&self) -> bool {
    self.options.is_empty()
  }
}

impl ChecklistCellData {
  pub fn selected_options(&self) -> Vec<SelectOption> {
    self
      .options
      .iter()
      .filter(|option| self.selected_option_ids.contains(&option.id))
      .cloned()
      .collect()
  }

  pub fn percentage_complete(&self) -> f64 {
    let selected_options = self.selected_option_ids.len();
    let total_options = self.options.len();

    if total_options == 0 {
      return 0.0;
    }
    ((selected_options as f64) / (total_options as f64) * 100.0).round() / 100.0
  }

  pub fn from_options(new_tasks: Vec<ChecklistCellInsertChangeset>) -> Self {
    let (options, selected_ids): (Vec<_>, Vec<_>) = new_tasks
      .into_iter()
      .map(|new_task| {
        let option = SelectOption::new(&new_task.name);
        let selected_id = new_task.is_complete.then(|| option.id.clone());
        (option, selected_id)
      })
      .unzip();
    let selected_option_ids = selected_ids.into_iter().flatten().collect();

    Self {
      options,
      selected_option_ids,
    }
  }
}

impl From<&Cell> for ChecklistCellData {
  fn from(cell: &Cell) -> Self {
    cell
      .get_as::<String>(CELL_DATA)
      .map(|data| serde_json::from_str::<ChecklistCellData>(&data).unwrap_or_default())
      .unwrap_or_default()
  }
}

impl From<ChecklistCellData> for Cell {
  fn from(cell_data: ChecklistCellData) -> Self {
    let data = serde_json::to_string(&cell_data).unwrap_or_default();
    let mut cell = new_cell_builder(FieldType::Checklist);
    cell.insert(CELL_DATA.into(), data.into());
    cell
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
