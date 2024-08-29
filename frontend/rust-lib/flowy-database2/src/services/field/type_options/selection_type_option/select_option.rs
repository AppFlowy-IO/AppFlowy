use crate::entities::SelectOptionCellDataPB;
use crate::services::field::SelectOptionIds;
use collab_database::entity::SelectOption;
#[derive(Debug)]
pub struct SelectOptionCellData {
  pub select_options: Vec<SelectOption>,
}

impl From<SelectOptionCellData> for SelectOptionCellDataPB {
  fn from(data: SelectOptionCellData) -> Self {
    SelectOptionCellDataPB {
      select_options: data
        .select_options
        .into_iter()
        .map(|option| option.into())
        .collect(),
    }
  }
}

pub fn make_selected_options(ids: SelectOptionIds, options: &[SelectOption]) -> Vec<SelectOption> {
  ids
    .iter()
    .flat_map(|option_id| {
      options
        .iter()
        .find(|option| &option.id == option_id)
        .cloned()
    })
    .collect()
}
