use flowy_derive::ProtoBuf;
use validator::Validate;

use crate::entities::{CellIdPB, SelectOptionPB};

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct ChecklistCellDataPB {
  #[pb(index = 1)]
  pub options: Vec<SelectOptionPB>,

  #[pb(index = 2)]
  pub selected_options: Vec<SelectOptionPB>,

  #[pb(index = 3)]
  pub percentage: f64,
}

#[derive(Debug, Clone, Default, ProtoBuf, Validate)]
pub struct ChecklistCellDataChangesetPB {
  #[pb(index = 1)]
  #[validate(nested)]
  pub cell_id: CellIdPB,

  #[pb(index = 2)]
  pub insert_task: Vec<String>,

  #[pb(index = 3)]
  pub delete_tasks: Vec<String>,

  #[pb(index = 4)]
  pub update_tasks: Vec<SelectOptionPB>,

  #[pb(index = 5)]
  pub completed_tasks: Vec<String>,

  #[pb(index = 6)]
  pub reorder: String,
}
