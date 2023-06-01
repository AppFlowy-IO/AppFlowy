use std::collections::HashMap;

use collab_database::rows::{Row, RowId};
use collab_database::views::RowOrder;

use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

use crate::entities::parser::NotEmptyStr;
use crate::services::database::{InsertedRow, UpdatedRow};

/// [RowPB] Describes a row. Has the id of the parent Block. Has the metadata of the row.
#[derive(Debug, Default, Clone, ProtoBuf, Eq, PartialEq)]
pub struct RowPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub height: i32,
}

impl std::convert::From<&Row> for RowPB {
  fn from(row: &Row) -> Self {
    Self {
      id: row.id.clone().into_inner(),
      height: row.height,
    }
  }
}

impl std::convert::From<Row> for RowPB {
  fn from(row: Row) -> Self {
    Self {
      id: row.id.into_inner(),
      height: row.height,
    }
  }
}
impl From<RowOrder> for RowPB {
  fn from(data: RowOrder) -> Self {
    Self {
      id: data.id.into_inner(),
      height: data.height,
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

  pub fn with_index(mut self, index: i32) -> Self {
    self.index = Some(index);
    self
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

impl std::convert::From<&Row> for InsertedRowPB {
  fn from(row: &Row) -> Self {
    Self::from(RowPB::from(row))
  }
}

impl From<InsertedRow> for InsertedRowPB {
  fn from(data: InsertedRow) -> Self {
    Self {
      row: data.row.into(),
      index: data.index,
      is_new: data.is_new,
    }
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct UpdatedRowPB {
  #[pb(index = 1)]
  pub row: RowPB,

  // Indicates the field ids of the cells that were updated in this row.
  #[pb(index = 2)]
  pub field_ids: Vec<String>,
}

impl From<UpdatedRow> for UpdatedRowPB {
  fn from(data: UpdatedRow) -> Self {
    Self {
      row: data.row.into(),
      field_ids: data.field_ids,
    }
  }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RowIdPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub row_id: String,

  #[pb(index = 3, one_of)]
  pub group_id: Option<String>,
}

pub struct RowIdParams {
  pub view_id: String,
  pub row_id: RowId,
  pub group_id: Option<String>,
}

impl TryInto<RowIdParams> for RowIdPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<RowIdParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseIdIsEmpty)?;
    let group_id = match self.group_id {
      Some(group_id) => Some(
        NotEmptyStr::parse(group_id)
          .map_err(|_| ErrorCode::GroupIdIsEmpty)?
          .0,
      ),
      None => None,
    };

    Ok(RowIdParams {
      view_id: view_id.0,
      row_id: RowId::from(self.row_id),
      group_id,
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
  pub start_row_id: Option<RowId>,
  pub group_id: Option<String>,
  pub cell_data_by_field_id: Option<HashMap<String, String>>,
}

impl TryInto<CreateRowParams> for CreateRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::ViewIdIsInvalid)?;
    let start_row_id = self.start_row_id.map(RowId::from);
    Ok(CreateRowParams {
      view_id: view_id.0,
      start_row_id,
      group_id: self.group_id,
      cell_data_by_field_id: self.data.map(|data| data.cell_data_by_field_id),
    })
  }
}
