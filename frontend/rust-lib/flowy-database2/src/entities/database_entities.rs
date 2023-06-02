use collab_database::rows::RowId;
use collab_database::user::DatabaseRecord;
use collab_database::views::DatabaseLayout;

use flowy_derive::ProtoBuf;
use flowy_error::{ErrorCode, FlowyError};

use crate::entities::parser::NotEmptyStr;
use crate::entities::{DatabaseLayoutPB, FieldIdPB, RowPB};
use crate::services::database::CreateDatabaseViewParams;

/// [DatabasePB] describes how many fields and blocks the grid has
#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct DatabasePB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub fields: Vec<FieldIdPB>,

  #[pb(index = 3)]
  pub rows: Vec<RowPB>,

  #[pb(index = 4)]
  pub layout_type: DatabaseLayoutPB,
}

#[derive(ProtoBuf, Default)]
pub struct CreateDatabaseViewPayloadPB {
  #[pb(index = 1)]
  pub name: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub layout_type: DatabaseLayoutPB,
}

impl TryInto<CreateDatabaseViewParams> for CreateDatabaseViewPayloadPB {
  type Error = FlowyError;

  fn try_into(self) -> Result<CreateDatabaseViewParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    Ok(CreateDatabaseViewParams {
      name: self.name,
      view_id: view_id.0,
      layout_type: self.layout_type.into(),
    })
  }
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct DatabaseIdPB {
  #[pb(index = 1)]
  pub value: String,
}

impl AsRef<str> for DatabaseIdPB {
  fn as_ref(&self) -> &str {
    &self.value
  }
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

  #[pb(index = 3)]
  pub to_row_id: String,
}

pub struct MoveRowParams {
  pub view_id: String,
  pub from_row_id: RowId,
  pub to_row_id: RowId,
}

impl TryInto<MoveRowParams> for MoveRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;

    Ok(MoveRowParams {
      view_id: view_id.0,
      from_row_id: RowId::from(self.from_row_id),
      to_row_id: RowId::from(self.to_row_id),
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
  pub from_row_id: RowId,
  pub to_group_id: String,
  pub to_row_id: Option<RowId>,
}

impl TryInto<MoveGroupRowParams> for MoveGroupRowPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveGroupRowParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let to_group_id =
      NotEmptyStr::parse(self.to_group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;

    Ok(MoveGroupRowParams {
      view_id: view_id.0,
      to_group_id: to_group_id.0,
      from_row_id: RowId::from(self.from_row_id),
      to_row_id: self.to_row_id.map(RowId::from),
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

impl From<DatabaseRecord> for DatabaseDescriptionPB {
  fn from(data: DatabaseRecord) -> Self {
    Self {
      name: data.name,
      database_id: data.database_id,
    }
  }
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
pub struct DatabaseLayoutMetaPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub layout: DatabaseLayoutPB,
}

#[derive(Clone, Debug)]
pub struct DatabaseLayoutMeta {
  pub view_id: String,
  pub layout: DatabaseLayout,
}

impl TryInto<DatabaseLayoutMeta> for DatabaseLayoutMetaPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DatabaseLayoutMeta, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id).map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?;
    let layout = self.layout.into();
    Ok(DatabaseLayoutMeta {
      view_id: view_id.0,
      layout,
    })
  }
}
