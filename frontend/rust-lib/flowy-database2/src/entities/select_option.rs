use crate::entities::parser::NotEmptyStr;
use crate::entities::{CellIdPB, CellIdParams};
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

#[derive(ProtoBuf_Enum, PartialEq, Eq, Debug, Clone)]
#[repr(u8)]
pub enum SelectOptionColorPB {
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

impl std::default::Default for SelectOptionColorPB {
  fn default() -> Self {
    SelectOptionColorPB::Purple
  }
}

/// [SelectOptionCellDataPB] contains a list of user's selected options and a list of all the options
/// that the cell can use.
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct SelectOptionCellDataPB {
  /// The available options that the cell can use.
  #[pb(index = 1)]
  pub options: Vec<SelectOptionPB>,

  /// The selected options for the cell.
  #[pb(index = 2)]
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
