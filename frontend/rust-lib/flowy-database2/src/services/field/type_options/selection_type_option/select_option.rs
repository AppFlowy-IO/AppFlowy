use crate::entities::SelectOptionCellDataPB;
use crate::services::field::SelectOptionIds;
use collab_database::database::gen_option_id;
use serde::{Deserialize, Serialize};

/// [SelectOption] represents an option for a single select, and multiple select.
#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct SelectOption {
  pub id: String,
  pub name: String,
  pub color: SelectOptionColor,
}

impl SelectOption {
  pub fn new(name: &str) -> Self {
    SelectOption {
      id: gen_option_id(),
      name: name.to_owned(),
      color: SelectOptionColor::default(),
    }
  }

  pub fn with_color(name: &str, color: SelectOptionColor) -> Self {
    SelectOption {
      id: gen_option_id(),
      name: name.to_owned(),
      color,
    }
  }
}

#[derive(PartialEq, Eq, Serialize, Deserialize, Debug, Clone)]
#[repr(u8)]
#[derive(Default)]
pub enum SelectOptionColor {
  #[default]
  Purple = 0,
  Pink = 1,
  LightPink = 2,
  Orange = 3,
  Yellow = 4,
  Lime = 5,
  Green = 6,
  Aqua = 7,
  Blue = 8,
}

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
