use crate::entities::{SelectOptionCellDataPB, SelectOptionColorPB, SelectOptionPB};
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
pub enum SelectOptionColor {
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

impl std::default::Default for SelectOptionColor {
  fn default() -> Self {
    SelectOptionColor::Purple
  }
}

#[derive(Debug)]
pub struct SelectOptionCellData {
  pub options: Vec<SelectOption>,
  pub select_options: Vec<SelectOption>,
}

impl From<SelectOptionCellData> for SelectOptionCellDataPB {
  fn from(data: SelectOptionCellData) -> Self {
    SelectOptionCellDataPB {
      options: data.options.into_iter().map(|option| option.into).collect(),
      select_options: data
        .select_options
        .into_iter()
        .map(|option| option.into)
        .collect(),
    }
  }
}

impl From<SelectOption> for SelectOptionPB {
  fn from(data: SelectOption) -> Self {
    SelectOptionPB {
      id: data.id,
      name: data.name,
      color: data.color.into(),
    }
  }
}

impl From<SelectOptionColor> for SelectOptionColorPB {
  fn from(data: SelectOptionColor) -> Self {
    match data {
      SelectOptionColor::Purple => SelectOptionColorPB::Purple,
      SelectOptionColor::Pink => SelectOptionColorPB::Pink,
      SelectOptionColor::LightPink => SelectOptionColorPB::LightPink,
      SelectOptionColor::Orange => SelectOptionColorPB::Orange,
      SelectOptionColor::Yellow => SelectOptionColorPB::Yellow,
      SelectOptionColor::Lime => SelectOptionColorPB::Lime,
      SelectOptionColor::Green => SelectOptionColorPB::Green,
      SelectOptionColor::Aqua => SelectOptionColorPB::Aqua,
      SelectOptionColor::Blue => SelectOptionColorPB::Blue,
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

pub struct SelectedSelectOptions {
  pub(crate) options: Vec<SelectOption>,
}

impl std::convert::From<SelectOptionCellData> for SelectedSelectOptions {
  fn from(data: SelectOptionCellData) -> Self {
    Self {
      options: data.select_options,
    }
  }
}
