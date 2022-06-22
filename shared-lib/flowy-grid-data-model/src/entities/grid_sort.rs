use crate::parser::NotEmptyStr;
use flowy_derive::ProtoBuf;
use flowy_error_code::ErrorCode;

use crate::revision::GridSortRevision;
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSort {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub field_id: Option<String>,
}

impl std::convert::From<&GridSortRevision> for GridSort {
    fn from(rev: &GridSortRevision) -> Self {
        GridSort {
            id: rev.id.clone(),

            field_id: rev.field_id.clone(),
        }
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RepeatedGridSort {
    #[pb(index = 1)]
    pub items: Vec<GridSort>,
}

impl std::convert::From<&Vec<GridSortRevision>> for RepeatedGridSort {
    fn from(revs: &Vec<GridSortRevision>) -> Self {
        RepeatedGridSort {
            items: revs.iter().map(|rev| rev.into()).collect(),
        }
    }
}

impl std::convert::From<Vec<GridSort>> for RepeatedGridSort {
    fn from(items: Vec<GridSort>) -> Self {
        Self { items }
    }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct CreateGridSortPayload {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,
}

pub struct CreateGridSortParams {
    pub field_id: Option<String>,
}

impl TryInto<CreateGridSortParams> for CreateGridSortPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridSortParams, Self::Error> {
        let field_id = match self.field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(CreateGridSortParams { field_id })
    }
}
