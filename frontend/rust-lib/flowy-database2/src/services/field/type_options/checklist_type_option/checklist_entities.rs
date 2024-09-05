use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};
use collab::util::AnyMapExt;
use collab_database::entity::SelectOption;
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

  pub fn from_options(options: Vec<(String, bool)>) -> Self {
    let (options, selected_ids): (Vec<_>, Vec<_>) = options
      .into_iter()
      .map(|(name, is_selected)| {
        let option = SelectOption::new(&name);
        let selected_id = is_selected.then(|| option.id.clone());
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
  /// List of option names that will be inserted
  pub insert_options: Vec<(String, bool)>,
  pub selected_option_ids: Vec<String>,
  pub delete_option_ids: Vec<String>,
  pub update_options: Vec<SelectOption>,
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
