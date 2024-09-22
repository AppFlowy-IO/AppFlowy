use crate::entities::parser::NotEmptyStr;
use crate::entities::{CellIdPB, CellIdParams};
use crate::services::field::checklist_type_option::ChecklistTypeOption;
use collab_database::fields::select_type_option::{
  MultiSelectTypeOption, SelectOption, SelectOptionColor, SelectTypeOption, SingleSelectTypeOption,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;

/// [SelectOptionPB] represents an option for a single select, and multiple select.
#[derive(Clone, Debug, Default, PartialEq, Eq, ProtoBuf)]
pub struct SelectOptionPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub color: SelectOptionColorPB,
}

impl From<SelectOption> for SelectOptionPB {
  fn from(data: SelectOption) -> Self {
    Self {
      id: data.id,
      name: data.name,
      color: data.color.into(),
    }
  }
}

impl From<SelectOptionPB> for SelectOption {
  fn from(data: SelectOptionPB) -> Self {
    Self {
      id: data.id,
      name: data.name,
      color: data.color.into(),
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedSelectOptionPayload {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3)]
  pub row_id: String,

  #[pb(index = 4)]
  pub items: Vec<SelectOptionPB>,
}

#[derive(ProtoBuf_Enum, PartialEq, Eq, Debug, Clone, Default)]
#[repr(u8)]
pub enum SelectOptionColorPB {
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

impl From<SelectOptionColorPB> for SelectOptionColor {
  fn from(data: SelectOptionColorPB) -> Self {
    match data {
      SelectOptionColorPB::Purple => SelectOptionColor::Purple,
      SelectOptionColorPB::Pink => SelectOptionColor::Pink,
      SelectOptionColorPB::LightPink => SelectOptionColor::LightPink,
      SelectOptionColorPB::Orange => SelectOptionColor::Orange,
      SelectOptionColorPB::Yellow => SelectOptionColor::Yellow,
      SelectOptionColorPB::Lime => SelectOptionColor::Lime,
      SelectOptionColorPB::Green => SelectOptionColor::Green,
      SelectOptionColorPB::Aqua => SelectOptionColor::Aqua,
      SelectOptionColorPB::Blue => SelectOptionColor::Blue,
    }
  }
}

/// [SelectOptionCellDataPB] contains a list of user's selected options
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionCellDataPB {
  #[pb(index = 1)]
  pub select_options: Vec<SelectOptionPB>,
}

/// [SelectOptionChangesetPB] describes the changes of a FieldTypeOptionData. For the moment,
/// it is used by [MultiSelectTypeOptionPB] and [SingleSelectTypeOptionPB].
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionChangesetPB {
  #[pb(index = 1)]
  pub cell_identifier: CellIdPB,

  #[pb(index = 2)]
  pub insert_options: Vec<SelectOptionPB>,

  #[pb(index = 3)]
  pub update_options: Vec<SelectOptionPB>,

  #[pb(index = 4)]
  pub delete_options: Vec<SelectOptionPB>,
}

pub struct SelectOptionChangeset {
  pub cell_path: CellIdParams,
  pub insert_options: Vec<SelectOptionPB>,
  pub update_options: Vec<SelectOptionPB>,
  pub delete_options: Vec<SelectOptionPB>,
}

impl TryInto<SelectOptionChangeset> for SelectOptionChangesetPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SelectOptionChangeset, Self::Error> {
    let cell_identifier = self.cell_identifier.try_into()?;
    Ok(SelectOptionChangeset {
      cell_path: cell_identifier,
      insert_options: self.insert_options,
      update_options: self.update_options,
      delete_options: self.delete_options,
    })
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionCellChangesetPB {
  #[pb(index = 1)]
  pub cell_identifier: CellIdPB,

  #[pb(index = 2)]
  pub insert_option_ids: Vec<String>,

  #[pb(index = 3)]
  pub delete_option_ids: Vec<String>,
}

pub struct SelectOptionCellChangesetParams {
  pub cell_identifier: CellIdParams,
  pub insert_option_ids: Vec<String>,
  pub delete_option_ids: Vec<String>,
}

impl TryInto<SelectOptionCellChangesetParams> for SelectOptionCellChangesetPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SelectOptionCellChangesetParams, Self::Error> {
    let cell_identifier: CellIdParams = self.cell_identifier.try_into()?;
    let insert_option_ids = self
      .insert_option_ids
      .into_iter()
      .flat_map(|option_id| match NotEmptyStr::parse(option_id) {
        Ok(option_id) => Some(option_id.0),
        Err(_) => {
          tracing::error!("The insert option id should not be empty");
          None
        },
      })
      .collect::<Vec<String>>();

    let delete_option_ids = self
      .delete_option_ids
      .into_iter()
      .flat_map(|option_id| match NotEmptyStr::parse(option_id) {
        Ok(option_id) => Some(option_id.0),
        Err(_) => {
          tracing::error!("The deleted option id should not be empty");
          None
        },
      })
      .collect::<Vec<String>>();

    Ok(SelectOptionCellChangesetParams {
      cell_identifier,
      insert_option_ids,
      delete_option_ids,
    })
  }
}

// Single select
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SingleSelectTypeOptionPB {
  #[pb(index = 1)]
  pub options: Vec<SelectOptionPB>,

  #[pb(index = 2)]
  pub disable_color: bool,
}

impl From<SelectTypeOption> for SingleSelectTypeOptionPB {
  fn from(data: SelectTypeOption) -> Self {
    Self {
      options: data
        .options
        .into_iter()
        .map(|option| option.into())
        .collect(),
      disable_color: data.disable_color,
    }
  }
}

impl From<SingleSelectTypeOptionPB> for SingleSelectTypeOption {
  fn from(data: SingleSelectTypeOptionPB) -> Self {
    SingleSelectTypeOption(SelectTypeOption {
      options: data
        .options
        .into_iter()
        .map(|option| option.into())
        .collect(),
      disable_color: data.disable_color,
    })
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct MultiSelectTypeOptionPB {
  #[pb(index = 1)]
  pub options: Vec<SelectOptionPB>,

  #[pb(index = 2)]
  pub disable_color: bool,
}

impl From<SelectTypeOption> for MultiSelectTypeOptionPB {
  fn from(data: SelectTypeOption) -> Self {
    Self {
      options: data
        .options
        .into_iter()
        .map(|option| option.into())
        .collect(),
      disable_color: data.disable_color,
    }
  }
}

impl From<MultiSelectTypeOptionPB> for MultiSelectTypeOption {
  fn from(data: MultiSelectTypeOptionPB) -> Self {
    MultiSelectTypeOption(SelectTypeOption {
      options: data
        .options
        .into_iter()
        .map(|option| option.into())
        .collect(),
      disable_color: data.disable_color,
    })
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct ChecklistTypeOptionPB {
  #[pb(index = 1)]
  pub config: String,
}

impl From<ChecklistTypeOption> for ChecklistTypeOptionPB {
  fn from(_data: ChecklistTypeOption) -> Self {
    Self {
      config: "".to_string(),
    }
  }
}

impl From<ChecklistTypeOptionPB> for ChecklistTypeOption {
  fn from(_data: ChecklistTypeOptionPB) -> Self {
    Self
  }
}
