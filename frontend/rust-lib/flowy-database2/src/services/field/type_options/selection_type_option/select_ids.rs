use collab::util::AnyMapExt;
use std::str::FromStr;

use collab_database::rows::{new_cell_builder, Cell};

use flowy_error::FlowyError;

use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};

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
    let mut cell = new_cell_builder(field_type);
    cell.insert(CELL_DATA.into(), self.to_string().into());
    cell
  }
}

impl TypeOptionCellData for SelectOptionIds {
  fn is_cell_empty(&self) -> bool {
    self.is_empty()
  }
}

impl From<&Cell> for SelectOptionIds {
  fn from(cell: &Cell) -> Self {
    let value: String = cell.get_as(CELL_DATA).unwrap_or_default();
    Self::from_str(&value).unwrap_or_default()
  }
}

impl FromStr for SelectOptionIds {
  type Err = FlowyError;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    if s.is_empty() {
      return Ok(Self(vec![]));
    }
    let ids = s
      .split(SELECTION_IDS_SEPARATOR)
      .map(|id| id.to_string())
      .collect::<Vec<String>>();
    Ok(Self(ids))
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
      Some(s) => Self::from_str(&s).unwrap_or_default(),
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
