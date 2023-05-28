use std::convert::TryInto;

use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

use crate::entities::parser::NotEmptyStr;
use crate::entities::{FieldType, RowPB};
use crate::services::group::{GroupChangeset, GroupData, GroupSetting};

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
      rows: group_data.rows.into_iter().map(RowPB::from).collect(),
      is_default: group_data.is_default,
      is_visible: group_data.is_visible,
    }
  }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GroupByFieldPayloadPB {
  #[pb(index = 1)]
  pub field_id: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub field_type: FieldType,
}

impl TryInto<GroupByFieldParams> for GroupByFieldPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<GroupByFieldParams, Self::Error> {
    let field_id = NotEmptyStr::parse(self.field_id)
      .map_err(|_| ErrorCode::FieldIdIsEmpty)?
      .0;
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::ViewIdIsInvalid)?
      .0;

    Ok(GroupByFieldParams {
      field_id,
      view_id,
      field_type: self.field_type,
    })
  }
}

pub struct GroupByFieldParams {
  pub field_id: String,
  pub view_id: String,
  pub field_type: FieldType,
}

pub struct DeleteGroupParams {
  pub view_id: String,
  pub field_id: String,
  pub group_id: String,
  pub field_type: FieldType,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct UpdateGroupPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub group_id: String,

  #[pb(index = 3, one_of)]
  pub name: Option<String>,

  #[pb(index = 4, one_of)]
  pub visible: Option<bool>,
}

impl TryInto<UpdateGroupParams> for UpdateGroupPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<UpdateGroupParams, Self::Error> {
    let view_id = NotEmptyStr::parse(self.view_id)
      .map_err(|_| ErrorCode::ViewIdIsInvalid)?
      .0;
    let group_id = NotEmptyStr::parse(self.group_id)
      .map_err(|_| ErrorCode::GroupIdIsEmpty)?
      .0;

    Ok(UpdateGroupParams {
      view_id,
      group_id,
      name: self.name,
      visible: self.visible,
    })
  }
}

pub struct UpdateGroupParams {
  pub view_id: String,
  pub group_id: String,
  pub name: Option<String>,
  pub visible: Option<bool>,
}

impl From<UpdateGroupParams> for GroupChangeset {
  fn from(params: UpdateGroupParams) -> Self {
    Self {
      group_id: params.group_id,
      name: params.name,
      visible: params.visible,
    }
  }
}
