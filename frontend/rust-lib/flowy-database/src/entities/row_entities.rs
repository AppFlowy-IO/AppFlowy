use crate::entities::parser::NotEmptyStr;

use database_model::RowRevision;
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use std::collections::HashMap;
use std::sync::Arc;

/// [RowPB] Describes a row. Has the id of the parent Block. Has the metadata of the row.
#[derive(Debug, Default, Clone, ProtoBuf, Eq, PartialEq)]
pub struct RowPB {
  #[pb(index = 1)]
  pub block_id: String,

  #[pb(index = 2)]
  pub id: String,

  #[pb(index = 3)]
  pub height: i32,
}

impl RowPB {
  pub fn row_id(&self) -> &str {
    &self.id
  }

  pub fn block_id(&self) -> &str {
    &self.block_id
  }
}

impl std::convert::From<&RowRevision> for RowPB {
  fn from(rev: &RowRevision) -> Self {
    Self {
      block_id: rev.block_id.clone(),
      id: rev.id.clone(),
      height: rev.height,
    }
  }
}

impl std::convert::From<&mut RowRevision> for RowPB {
  fn from(rev: &mut RowRevision) -> Self {
    Self {
      block_id: rev.block_id.clone(),
      id: rev.id.clone(),
      height: rev.height,
    }
  }
}

impl std::convert::From<&Arc<RowRevision>> for RowPB {
  fn from(rev: &Arc<RowRevision>) -> Self {
    Self {
      block_id: rev.block_id.clone(),
      id: rev.id.clone(),
      height: rev.height,
    }
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct OptionalRowPB {
  #[pb(index = 1, one_of)]
  pub row: Option<RowPB>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedRowPB {
  #[pb(index = 1)]
  pub items: Vec<RowPB>,
}

impl std::convert::From<Vec<RowPB>> for RepeatedRowPB {
  fn from(items: Vec<RowPB>) -> Self {
    Self { items }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct InsertedRowPB {
  #[pb(index = 1)]
  pub row: RowPB,

  #[pb(index = 2, one_of)]
  pub index: Option<i32>,

  #[pb(index = 3)]
  pub is_new: bool,
}

impl InsertedRowPB {
  pub fn new(row: RowPB) -> Self {
    Self {
      row,
      index: None,
      is_new: false,
    }
  }

  pub fn with_index(row: RowPB, index: i32) -> Self {
    Self {
      row,
      index: Some(index),
      is_new: false,
    }
  }
}

impl std::convert::From<RowPB> for InsertedRowPB {
  fn from(row: RowPB) -> Self {
    Self {
      row,
      index: None,
      is_new: false,
    }
  }
}

impl std::convert::From<&RowRevision> for InsertedRowPB {
  fn from(row: &RowRevision) -> Self {
    let row_order = RowPB::from(row);
    Self::from(row_order)
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct UpdatedRowPB {
  #[pb(index = 1)]
  pub row: RowPB,

  // represents as the cells that were updated in this row.
  #[pb(index = 2)]
  pub field_ids: Vec<String>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowIdPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub row_id: String,
}

pub struct RowIdParams {
  pub view_id: String,
  pub row_id: String,
}

impl TryInto<RowIdParams> for RowIdPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<RowIdParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let row_id = NotEmptyStr::parse(self.row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

    Ok(RowIdParams {
      view_id: view_id.0,
      row_id: row_id.0,
    })
  }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct BlockRowIdPB {
  #[pb(index = 1)]
  pub block_id: String,

  #[pb(index = 2)]
  pub row_id: String,
}

#[derive(ProtoBuf, Default)]
pub struct CreateRowPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub start_row_id: Option<String>,

  #[pb(index = 3, one_of)]
  pub group_id: Option<String>,

  #[pb(index = 4, one_of)]
  pub data: Option<RowDataPB>,
}

#[derive(ProtoBuf, Default)]
pub struct RowDataPB {
  #[pb(index = 1)]
  pub cell_data_by_field_id: HashMap<String, String>,
}

#[derive(Default)]
pub struct CreateRowParams {
  pub view_id: String,
  pub start_row_id: Option<String>,
  pub group_id: Option<String>,
  pub cell_data_by_field_id: Option<HashMap<String, String>>,
}

impl TryInto<CreateRowParams> for CreateRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::ViewIdIsInvalid)?;
    let start_row_id = match self.start_row_id {
      None => None,
      Some(start_row_id) => Some(
        NotEmptyStr::parse(start_row_id)
          .map_err(|_| ErrorCode::RowIdIsEmpty)?
          .0,
      ),
    };

    Ok(CreateRowParams {
      view_id: view_id.0,
      start_row_id,
      group_id: self.group_id,
      cell_data_by_field_id: self.data.map(|data| data.cell_data_by_field_id),
    })
  }
}
