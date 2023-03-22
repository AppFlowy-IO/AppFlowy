use crate::entities::parser::NotEmptyStr;
use crate::entities::{FieldIdPB, LayoutTypePB, RowPB};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

/// [DatabasePB] describes how many fields and blocks the grid has
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DatabasePB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub fields: Vec<FieldIdPB>,

  #[pb(index = 3)]
  pub rows: Vec<RowPB>,
}

#[derive(ProtoBuf, Default)]
pub struct CreateDatabasePayloadPB {
  #[pb(index = 1)]
  pub name: String,
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct DatabaseViewIdPB {
  #[pb(index = 1)]
  pub value: String,
}

impl AsRef<str> for DatabaseViewIdPB {
  fn as_ref(&self) -> &str {
    &self.value
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveFieldPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub field_id: String,

  #[pb(index = 3)]
  pub from_index: i32,

  #[pb(index = 4)]
  pub to_index: i32,
}

#[derive(Clone)]
pub struct MoveFieldParams {
  pub view_id: String,
  pub field_id: String,
  pub from_index: i32,
  pub to_index: i32,
}

impl TryInto<MoveFieldParams> for MoveFieldPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveFieldParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let item_id = NotEmptyStr::parse(self.field_id).map_err(|_| ErrorCode::InvalidData)?;
    Ok(MoveFieldParams {
      view_id: view_id.0,
      field_id: item_id.0,
      from_index: self.from_index,
      to_index: self.to_index,
    })
  }
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveRowPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from_row_id: String,

  #[pb(index = 4)]
  pub to_row_id: String,
}

pub struct MoveRowParams {
  pub view_id: String,
  pub from_row_id: String,
  pub to_row_id: String,
}

impl TryInto<MoveRowParams> for MoveRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let from_row_id = NotEmptyStr::parse(self.from_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
    let to_row_id = NotEmptyStr::parse(self.to_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;

    Ok(MoveRowParams {
      view_id: view_id.0,
      from_row_id: from_row_id.0,
      to_row_id: to_row_id.0,
    })
  }
}
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct MoveGroupRowPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from_row_id: String,

  #[pb(index = 3)]
  pub to_group_id: String,

  #[pb(index = 4, one_of)]
  pub to_row_id: Option<String>,
}

pub struct MoveGroupRowParams {
  pub view_id: String,
  pub from_row_id: String,
  pub to_group_id: String,
  pub to_row_id: Option<String>,
}

impl TryInto<MoveGroupRowParams> for MoveGroupRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveGroupRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let from_row_id = NotEmptyStr::parse(self.from_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?;
    let to_group_id =
      NotEmptyStr::parse(self.to_group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;

    let to_row_id = match self.to_row_id {
      None => None,
      Some(to_row_id) => Some(
        NotEmptyStr::parse(to_row_id)
          .map_err(|_| ErrorCode::RowIdIsEmpty)?
          .0,
      ),
    };

    Ok(MoveGroupRowParams {
      view_id: view_id.0,
      from_row_id: from_row_id.0,
      to_group_id: to_group_id.0,
      to_row_id,
    })
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct DatabaseDescriptionPB {
  #[pb(index = 1)]
  pub name: String,

  #[pb(index = 2)]
  pub database_id: String,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedDatabaseDescriptionPB {
  #[pb(index = 1)]
  pub items: Vec<DatabaseDescriptionPB>,
}

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DatabaseGroupIdPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub group_id: String,
}

pub struct DatabaseGroupIdParams {
  pub view_id: String,
  pub group_id: String,
}

impl TryInto<DatabaseGroupIdParams> for DatabaseGroupIdPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DatabaseGroupIdParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let group_id = NotEmptyStr::parse(self.group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;
    Ok(DatabaseGroupIdParams {
      view_id: view_id.0,
      group_id: group_id.0,
    })
  }
}
#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct DatabaseLayoutIdPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub layout: LayoutTypePB,
}
