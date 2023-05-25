use collab::core::any_map::AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};

use flowy_error::FlowyResult;

use crate::entities::FieldType;
use crate::services::cell::{DecodedCellData, FromCellString};
use crate::services::field::CELL_DATA;

pub const SELECTION_IDS_SEPARATOR: &str = ",";

/// List of select option ids
///
/// Calls [to_string] will return a string consists list of ids,
/// placing a commas separator between each
///
#[derive(Default, Clone, Debug)]
pub struct SelectOptionIds(Vec<String>);

impl SelectOptionIds {
  pub fn new() -> Self {
    Self::default()
  }
  pub fn into_inner(self) -> Vec<String> {
    self.0
  }

  pub fn to_cell_data(&self, field_type: FieldType) -> Cell {
    new_cell_builder(field_type)
      .insert_str_value(CELL_DATA, self.to_string())
      .build()
  }
}

impl FromCellString for SelectOptionIds {
  fn from_cell_str(s: &str) -> FlowyResult<Self>
  where
    Self: Sized,
  {
    Ok(Self::from(s.to_owned()))
  }
}

impl From<&Cell> for SelectOptionIds {
  fn from(cell: &Cell) -> Self {
    let value = cell.get_str_value(CELL_DATA).unwrap_or_default();
    Self::from(value)
  }
}

impl std::convert::From<String> for SelectOptionIds {
  fn from(s: String) -> Self {
    if s.is_empty() {
      return Self(vec![]);
    }

    let ids = s
      .split(SELECTION_IDS_SEPARATOR)
      .map(|id| id.to_string())
      .collect::<Vec<String>>();
    Self(ids)
  }
}

impl std::convert::From<Vec<String>> for SelectOptionIds {
  fn from(ids: Vec<String>) -> Self {
    let ids = ids
      .into_iter()
      .filter(|id| !id.is_empty())
      .collect::<Vec<String>>();
    Self(ids)
  }
}

impl ToString for SelectOptionIds {
  /// Returns a string that consists list of ids, placing a commas
  /// separator between each
  fn to_string(&self) -> String {
    self.0.join(SELECTION_IDS_SEPARATOR)
  }
}

impl std::convert::From<Option<String>> for SelectOptionIds {
  fn from(s: Option<String>) -> Self {
    match s {
      None => Self(vec![]),
      Some(s) => Self::from(s),
    }
  }
}

impl std::ops::Deref for SelectOptionIds {
  type Target = Vec<String>;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl std::ops::DerefMut for SelectOptionIds {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

impl DecodedCellData for SelectOptionIds {
  type Object = SelectOptionIds;

  fn is_empty(&self) -> bool {
    self.0.is_empty()
  }
}
