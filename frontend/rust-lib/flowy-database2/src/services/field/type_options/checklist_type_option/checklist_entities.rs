use crate::entities::FieldType;
use crate::services::cell::{FromCellChangeset, ToCellChangeset};
use crate::services::field::{SelectOption, CELL_DATA};
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};
use flowy_error::{internal_error, FlowyResult};
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
    (selected_options as f64) / (total_options as f64)
  }

  pub fn from_options(options: Vec<String>) -> Self {
    let options = options
      .into_iter()
      .map(|option_name| SelectOption::new(&option_name))
      .collect();

    Self {
      options,
      ..Default::default()
    }
  }
}

impl From<&Cell> for ChecklistCellData {
  fn from(cell: &Cell) -> Self {
    cell
      .get_str_value(CELL_DATA)
      .map(|data| serde_json::from_str::<ChecklistCellData>(&data).unwrap_or_default())
      .unwrap_or_default()
  }
}

impl From<ChecklistCellData> for Cell {
  fn from(cell_data: ChecklistCellData) -> Self {
    let data = serde_json::to_string(&cell_data).unwrap_or_default();
    new_cell_builder(FieldType::Checklist)
      .insert_str_value(CELL_DATA, data)
      .build()
  }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ChecklistCellChangeset {
  /// List of option names that will be inserted
  pub insert_options: Vec<String>,
  pub selected_option_ids: Vec<String>,
  pub delete_option_ids: Vec<String>,
  pub update_options: Vec<SelectOption>,
}

impl FromCellChangeset for ChecklistCellChangeset {
  fn from_changeset(changeset: String) -> FlowyResult<Self>
  where
    Self: Sized,
  {
    serde_json::from_str::<ChecklistCellChangeset>(&changeset).map_err(internal_error)
  }
}

impl ToCellChangeset for ChecklistCellChangeset {
  fn to_cell_changeset_str(&self) -> String {
    serde_json::to_string(self).unwrap_or_default()
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
