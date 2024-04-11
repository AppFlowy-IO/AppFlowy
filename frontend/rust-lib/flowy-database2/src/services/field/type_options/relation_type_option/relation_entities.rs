use std::sync::Arc;

use collab::preclude::Any;
use collab_database::rows::{new_cell_builder, Cell, RowId};

use crate::entities::FieldType;
use crate::services::field::{TypeOptionCellData, CELL_DATA};

#[derive(Debug, Clone, Default)]
pub struct RelationCellData {
  pub row_ids: Vec<RowId>,
}

impl From<&Cell> for RelationCellData {
  fn from(value: &Cell) -> Self {
    let row_ids = match value.get(CELL_DATA) {
      Some(Any::Array(array)) => array
        .iter()
        .flat_map(|item| {
          if let Any::String(string) = item {
            Some(RowId::from(string.clone().to_string()))
          } else {
            None
          }
        })
        .collect(),
      _ => vec![],
    };
    Self { row_ids }
  }
}

impl From<&RelationCellData> for Cell {
  fn from(value: &RelationCellData) -> Self {
    let data = Any::Array(Arc::from(
      value
        .row_ids
        .clone()
        .into_iter()
        .map(|id| Any::String(Arc::from(id.to_string())))
        .collect::<Vec<_>>(),
    ));
    new_cell_builder(FieldType::Relation)
      .insert_any(CELL_DATA, data)
      .build()
  }
}

impl From<String> for RelationCellData {
  fn from(s: String) -> Self {
    if s.is_empty() {
      return RelationCellData { row_ids: vec![] };
    }

    let ids = s
      .split(", ")
      .map(|id| id.to_string().into())
      .collect::<Vec<_>>();

    RelationCellData { row_ids: ids }
  }
}

impl TypeOptionCellData for RelationCellData {
  fn is_cell_empty(&self) -> bool {
    self.row_ids.is_empty()
  }
}

impl ToString for RelationCellData {
  fn to_string(&self) -> String {
    self
      .row_ids
      .iter()
      .map(|id| id.to_string())
      .collect::<Vec<_>>()
      .join(", ")
  }
}

#[derive(Debug, Clone, Default)]
pub struct RelationCellChangeset {
  pub inserted_row_ids: Vec<RowId>,
  pub removed_row_ids: Vec<RowId>,
}
