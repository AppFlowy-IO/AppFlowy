use crate::entities::parser::NotEmptyStr;
use crate::entities::{CreateRowParams, FieldType, GridLayout, RowPB};
use crate::services::group::Group;
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use grid_rev_model::{FieldTypeRevision, GroupConfigurationRevision};
use std::convert::TryInto;
use std::sync::Arc;

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct CreateBoardCardPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub group_id: String,

    #[pb(index = 3, one_of)]
    pub start_row_id: Option<String>,
}

impl TryInto<CreateRowParams> for CreateBoardCardPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let group_id = NotEmptyStr::parse(self.group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;
        let start_row_id = match self.start_row_id {
            None => None,
            Some(start_row_id) => Some(NotEmptyStr::parse(start_row_id).map_err(|_| ErrorCode::RowIdIsEmpty)?.0),
        };
        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id,
            group_id: Some(group_id.0),
            layout: GridLayout::Board,
        })
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GroupConfigurationPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub field_id: String,
}

impl std::convert::From<&GroupConfigurationRevision> for GroupConfigurationPB {
    fn from(rev: &GroupConfigurationRevision) -> Self {
        GroupConfigurationPB {
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

impl std::convert::From<Group> for GroupPB {
    fn from(group: Group) -> Self {
        Self {
            field_id: group.field_id,
            group_id: group.id,
            desc: group.name,
            rows: group.rows,
            is_default: group.is_default,
            is_visible: group.is_visible,
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGroupConfigurationPB {
    #[pb(index = 1)]
    pub items: Vec<GroupConfigurationPB>,
}

impl std::convert::From<Vec<GroupConfigurationPB>> for RepeatedGroupConfigurationPB {
    fn from(items: Vec<GroupConfigurationPB>) -> Self {
        Self { items }
    }
}

impl std::convert::From<Vec<Arc<GroupConfigurationRevision>>> for RepeatedGroupConfigurationPB {
    fn from(revs: Vec<Arc<GroupConfigurationRevision>>) -> Self {
        RepeatedGroupConfigurationPB {
            items: revs.iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct InsertGroupPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,
}

impl TryInto<InsertGroupParams> for InsertGroupPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<InsertGroupParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;

        Ok(InsertGroupParams {
            field_id,
            field_type_rev: self.field_type.into(),
        })
    }
}

pub struct InsertGroupParams {
    pub field_id: String,
    pub field_type_rev: FieldTypeRevision,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DeleteGroupPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub group_id: String,

    #[pb(index = 3)]
    pub field_type: FieldType,
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

        Ok(DeleteGroupParams {
            field_id,
            field_type_rev: self.field_type.into(),
            group_id,
        })
    }
}

pub struct DeleteGroupParams {
    pub field_id: String,
    pub group_id: String,
    pub field_type_rev: FieldTypeRevision,
}
