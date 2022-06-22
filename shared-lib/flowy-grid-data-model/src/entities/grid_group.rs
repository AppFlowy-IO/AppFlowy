use crate::parser::NotEmptyStr;
use flowy_derive::ProtoBuf;
use flowy_error_code::ErrorCode;

use crate::revision::GridGroupRevision;
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridGroup {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub group_field_id: Option<String>,

    #[pb(index = 3, one_of)]
    pub sub_group_field_id: Option<String>,
}

impl std::convert::From<&GridGroupRevision> for GridGroup {
    fn from(rev: &GridGroupRevision) -> Self {
        GridGroup {
            id: rev.id.clone(),
            group_field_id: rev.field_id.clone(),
            sub_group_field_id: rev.sub_field_id.clone(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridGroup {
    #[pb(index = 1)]
    pub items: Vec<GridGroup>,
}

impl std::convert::From<Vec<GridGroup>> for RepeatedGridGroup {
    fn from(items: Vec<GridGroup>) -> Self {
        Self { items }
    }
}

impl std::convert::From<&Vec<GridGroupRevision>> for RepeatedGridGroup {
    fn from(revs: &Vec<GridGroupRevision>) -> Self {
        RepeatedGridGroup {
            items: revs.iter().map(|rev| rev.into()).collect(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CreateGridGroupPayload {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,

    #[pb(index = 2, one_of)]
    pub sub_field_id: Option<String>,
}

pub struct CreateGridGroupParams {
    pub field_id: Option<String>,
    pub sub_field_id: Option<String>,
}

impl TryInto<CreateGridGroupParams> for CreateGridGroupPayload {
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
