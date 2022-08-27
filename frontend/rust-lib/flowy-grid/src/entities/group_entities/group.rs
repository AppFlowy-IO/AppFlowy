use crate::entities::{CreateRowParams, FieldType, GridLayout, RowPB};
use crate::services::group::Group;
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::{FieldTypeRevision, GroupConfigurationRevision};
use std::convert::TryInto;
use std::sync::Arc;

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct CreateBoardCardPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub group_id: String,
}

impl TryInto<CreateRowParams> for CreateBoardCardPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateRowParams, Self::Error> {
        let grid_id = NotEmptyStr::parse(self.grid_id).map_err(|_| ErrorCode::GridIdIsEmpty)?;
        let group_id = NotEmptyStr::parse(self.group_id).map_err(|_| ErrorCode::GroupIdIsEmpty)?;
        Ok(CreateRowParams {
            grid_id: grid_id.0,
            start_row_id: None,
            group_id: Some(group_id.0),
            layout: GridLayout::Board,
        })
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridGroupConfigurationPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub group_field_id: String,
}

impl std::convert::From<&GroupConfigurationRevision> for GridGroupConfigurationPB {
    fn from(rev: &GroupConfigurationRevision) -> Self {
        GridGroupConfigurationPB {
            id: rev.id.clone(),
            group_field_id: rev.field_id.clone(),
        }
    }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridGroupPB {
    #[pb(index = 1)]
    pub items: Vec<GroupPB>,
}

impl std::ops::Deref for RepeatedGridGroupPB {
    type Target = Vec<GroupPB>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for RepeatedGridGroupPB {
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
}

impl std::convert::From<Group> for GroupPB {
    fn from(group: Group) -> Self {
        Self {
            field_id: group.field_id,
            group_id: group.id,
            desc: group.name,
            rows: group.rows,
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridGroupConfigurationPB {
    #[pb(index = 1)]
    pub items: Vec<GridGroupConfigurationPB>,
}

impl std::convert::From<Vec<GridGroupConfigurationPB>> for RepeatedGridGroupConfigurationPB {
    fn from(items: Vec<GridGroupConfigurationPB>) -> Self {
        Self { items }
    }
}

impl std::convert::From<Vec<Arc<GroupConfigurationRevision>>> for RepeatedGridGroupConfigurationPB {
    fn from(revs: Vec<Arc<GroupConfigurationRevision>>) -> Self {
        RepeatedGridGroupConfigurationPB {
            items: revs.iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CreateGridGroupPayloadPB {
    #[pb(index = 1)]
    pub field_id: String,

    #[pb(index = 2)]
    pub field_type: FieldType,
}

impl TryInto<CreatGroupParams> for CreateGridGroupPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreatGroupParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;

        Ok(CreatGroupParams {
            field_id,
            field_type_rev: self.field_type.into(),
        })
    }
}

pub struct CreatGroupParams {
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
