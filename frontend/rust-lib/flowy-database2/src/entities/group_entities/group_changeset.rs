use std::fmt::Formatter;

use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

use crate::entities::parser::NotEmptyStr;
use crate::entities::{GroupPB, InsertedRowPB, RowMetaPB};

#[derive(Debug, Default, ProtoBuf)]
pub struct GroupRowsNotificationPB {
  #[pb(index = 1)]
  pub group_id: String,

  #[pb(index = 2)]
  pub inserted_rows: Vec<InsertedRowPB>,

  #[pb(index = 3)]
  pub deleted_rows: Vec<String>,

  #[pb(index = 4)]
  pub updated_rows: Vec<RowMetaPB>,
}

impl std::fmt::Display for GroupRowsNotificationPB {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    for inserted_row in &self.inserted_rows {
      f.write_fmt(format_args!(
        "Insert: {} row at {:?}",
        inserted_row.row_meta.id, inserted_row.index
      ))?;
    }

    for deleted_row in &self.deleted_rows {
      f.write_fmt(format_args!("Delete: {} row", deleted_row))?;
    }

    Ok(())
  }
}

impl GroupRowsNotificationPB {
  pub fn is_empty(&self) -> bool {
    self.inserted_rows.is_empty() && self.deleted_rows.is_empty() && self.updated_rows.is_empty()
  }

  pub fn new(group_id: String) -> Self {
    Self {
      group_id,
      ..Default::default()
    }
  }

  pub fn insert(group_id: String, inserted_rows: Vec<InsertedRowPB>) -> Self {
    Self {
      group_id,
      inserted_rows,
      ..Default::default()
    }
  }

  pub fn delete(group_id: String, deleted_rows: Vec<String>) -> Self {
    Self {
      group_id,
      deleted_rows,
      ..Default::default()
    }
  }

  pub fn update(group_id: String, updated_rows: Vec<RowMetaPB>) -> Self {
    Self {
      group_id,
      updated_rows,
      ..Default::default()
    }
  }
}
#[derive(Debug, Default, ProtoBuf)]
pub struct MoveGroupPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from_group_id: String,

  #[pb(index = 3)]
  pub to_group_id: String,
}

#[derive(Debug)]
pub struct MoveGroupParams {
  pub view_id: String,
  pub from_group_id: String,
  pub to_group_id: String,
}

impl TryInto<MoveGroupParams> for MoveGroupPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveGroupParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::DatabaseViewIdIsEmpty)?
      .0;
    let from_group_id = NotEmptyStr::parse(self.from_group_id)
      .map_err(|_| ErrorCode::GroupIdIsEmpty)?
      .0;
    let to_group_id = NotEmptyStr::parse(self.to_group_id)
      .map_err(|_| ErrorCode::GroupIdIsEmpty)?
      .0;
    Ok(MoveGroupParams {
      view_id,
      from_group_id,
      to_group_id,
    })
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GroupChangesPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub inserted_groups: Vec<InsertedGroupPB>,

  #[pb(index = 3)]
  pub initial_groups: Vec<GroupPB>,

  #[pb(index = 4)]
  pub deleted_groups: Vec<String>,

  #[pb(index = 5)]
  pub update_groups: Vec<GroupPB>,
}

impl GroupChangesPB {
  pub fn is_empty(&self) -> bool {
    self.initial_groups.is_empty()
      && self.inserted_groups.is_empty()
      && self.deleted_groups.is_empty()
      && self.update_groups.is_empty()
  }
}

#[derive(Debug, Default, ProtoBuf)]
pub struct InsertedGroupPB {
  #[pb(index = 1)]
  pub group: GroupPB,

  #[pb(index = 2)]
  pub index: i32,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct GroupRenameNotificationPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub group_id: String,
}
