use crate::entities::parser::NotEmptyStr;
use crate::entities::{FieldType, RowPB};
use crate::services::group::{GroupData, GroupSetting};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use std::convert::TryInto;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GroupSettingPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub field_id: String,
}

impl std::convert::From<&GroupSetting> for GroupSettingPB {
  fn from(rev: &GroupSetting) -> Self {
    GroupSettingPB {
      id: rev.id.clone(),
      field_id: rev.field_id.clone(),
    }
  }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGroupPB {
  #[pb(index = 1)]
  pub items: Vec<GroupPB>,
}

impl std::ops::Deref for RepeatedGroupPB {
  type Target = Vec<GroupPB>;
  fn deref(&self) -> &Self::Target {
    &self.items
  }
}

impl std::ops::DerefMut for RepeatedGroupPB {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.items
  }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct GroupPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub group_id: String,

  #[pb(index = 3)]
  pub desc: String,

  #[pb(index = 4)]
  pub rows: Vec<RowPB>,

  #[pb(index = 5)]
  pub is_default: bool,

  #[pb(index = 6)]
  pub is_visible: bool,
}

impl std::convert::From<GroupData> for GroupPB {
  fn from(group_data: GroupData) -> Self {
    Self {
      field_id: group_data.field_id,
      group_id: group_data.id,
      desc: group_data.name,
      rows: group_data
        .rows
        .into_iter()
        .map(|row| RowPB::from(row))
        .collect(),
      is_default: group_data.is_default,
      is_visible: group_data.is_visible,
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGroupSettingPB {
  #[pb(index = 1)]
  pub items: Vec<GroupSettingPB>,
}

impl std::convert::From<Vec<GroupSettingPB>> for RepeatedGroupSettingPB {
  fn from(items: Vec<GroupSettingPB>) -> Self {
    Self { items }
  }
}

impl std::convert::From<Vec<GroupSetting>> for RepeatedGroupSettingPB {
  fn from(group_settings: Vec<GroupSetting>) -> Self {
    RepeatedGroupSettingPB {
      items: group_settings
        .iter()
        .map(|setting| setting.into())
        .collect(),
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct InsertGroupPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub field_type: FieldType,

  #[pb(index = 3)]
  pub view_id: String,
}

impl TryInto<InsertGroupParams> for InsertGroupPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<InsertGroupParams, Self::Error> {
    let field_id = NotEmptyStr::parse(self.field_id)
      .map_err(|_| ErrorCode::FieldIdIsEmpty)?
      .0;

    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::ViewIdIsInvalid)?
      .0;

    Ok(InsertGroupParams {
      field_id,
      field_type: self.field_type,
      view_id,
    })
  }
}

pub struct InsertGroupParams {
  pub view_id: String,
  pub field_id: String,
  pub field_type: FieldType,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DeleteGroupPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub group_id: String,

  #[pb(index = 3)]
  pub field_type: FieldType,

  #[pb(index = 4)]
  pub view_id: String,
}

impl TryInto<DeleteGroupParams> for DeleteGroupPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DeleteGroupParams, Self::Error> {
    let field_id = NotEmptyStr::parse(self.field_id)
      .map_err(|_| ErrorCode::FieldIdIsEmpty)?
      .0;
    let group_id = NotEmptyStr::parse(self.group_id)
      .map_err(|_| ErrorCode::FieldIdIsEmpty)?
      .0;
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::ViewIdIsInvalid)?
      .0;

    Ok(DeleteGroupParams {
      field_id,
      field_type: self.field_type,
      group_id,
      view_id,
    })
  }
}

pub struct DeleteGroupParams {
  pub view_id: String,
  pub field_id: String,
  pub group_id: String,
  pub field_type: FieldType,
}
