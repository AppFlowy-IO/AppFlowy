use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::GridGroupRevision;
use flowy_sync::entities::grid::CreateGridGroupParams;
use std::convert::TryInto;
use std::sync::Arc;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridGroupPB {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub group_field_id: Option<String>,

    #[pb(index = 3, one_of)]
    pub sub_group_field_id: Option<String>,
}

impl std::convert::From<&GridGroupRevision> for GridGroupPB {
    fn from(rev: &GridGroupRevision) -> Self {
        GridGroupPB {
            id: rev.id.clone(),
            group_field_id: rev.field_id.clone(),
            sub_group_field_id: rev.sub_field_id.clone(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridGroupPB {
    #[pb(index = 1)]
    pub items: Vec<GridGroupPB>,
}

impl std::convert::From<Vec<GridGroupPB>> for RepeatedGridGroupPB {
    fn from(items: Vec<GridGroupPB>) -> Self {
        Self { items }
    }
}

impl std::convert::From<Vec<Arc<GridGroupRevision>>> for RepeatedGridGroupPB {
    fn from(revs: Vec<Arc<GridGroupRevision>>) -> Self {
        RepeatedGridGroupPB {
            items: revs.iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CreateGridGroupPayloadPB {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,

    #[pb(index = 2, one_of)]
    pub sub_field_id: Option<String>,
}

impl TryInto<CreateGridGroupParams> for CreateGridGroupPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridGroupParams, Self::Error> {
        let field_id = match self.field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        let sub_field_id = match self.sub_field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(CreateGridGroupParams { field_id, sub_field_id })
    }
}
