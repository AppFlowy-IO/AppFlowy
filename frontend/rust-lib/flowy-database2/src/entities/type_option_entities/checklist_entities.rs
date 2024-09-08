use collab_database::entity::SelectOption;
use collab_database::rows::RowId;

use flowy_derive::ProtoBuf;
use flowy_error::{ErrorCode, FlowyError};

use crate::entities::parser::NotEmptyStr;
use crate::entities::SelectOptionPB;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct ChecklistCellDataPB {
  #[pb(index = 1)]
  pub options: Vec<SelectOptionPB>,

  #[pb(index = 2)]
  pub selected_options: Vec<SelectOptionPB>,

  #[pb(index = 3)]
  pub percentage: f64,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct ChecklistCellDataChangesetPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3)]
  pub row_id: String,

  #[pb(index = 4)]
  pub insert_options: Vec<String>,

  #[pb(index = 5)]
  pub selected_option_ids: Vec<String>,

  #[pb(index = 6)]
  pub delete_option_ids: Vec<String>,

  #[pb(index = 7)]
  pub update_options: Vec<SelectOptionPB>,
}

#[derive(Debug)]
pub struct ChecklistCellDataChangesetParams {
  pub view_id: String,
  pub field_id: String,
  pub row_id: RowId,
  pub insert_options: Vec<String>,
  pub selected_option_ids: Vec<String>,
  pub delete_option_ids: Vec<String>,
  pub update_options: Vec<SelectOption>,
}

impl TryInto<ChecklistCellDataChangesetParams> for ChecklistCellDataChangesetPB {
  type Error = FlowyError;

  fn try_into(self) -> Result<ChecklistCellDataChangesetParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::ViewIdIsInvalid)?;
    let field_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?;
    let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

    Ok(ChecklistCellDataChangesetParams {
      view_id: view_id.0,
      field_id: field_id.0,
      row_id: RowId::from(row_id.0),
      insert_options: self.insert_options,
      selected_option_ids: self.selected_option_ids,
      delete_option_ids: self.delete_option_ids,
      update_options: self
        .update_options
        .into_iter()
        .map(SelectOption::from)
        .collect(),
    })
  }
}
