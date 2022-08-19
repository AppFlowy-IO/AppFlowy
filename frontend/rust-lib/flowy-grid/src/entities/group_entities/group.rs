use crate::entities::{FieldType, RowPB};
use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::GroupConfigurationRevision;
use flowy_sync::entities::grid::{CreateGridGroupParams, DeleteGroupParams};
use std::convert::TryInto;
use std::sync::Arc;

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

    #[pb(index = 3, one_of)]
    pub content: Option<Vec<u8>>,
}

impl TryInto<CreateGridGroupParams> for CreateGridGroupPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridGroupParams, Self::Error> {
        let field_id = NotEmptyStr::parse(self.field_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;

        Ok(CreateGridGroupParams {
            field_id,
            field_type_rev: self.field_type.into(),
            content: self.content,
        })
    }
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
