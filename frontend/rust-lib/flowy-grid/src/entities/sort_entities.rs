use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::GridSortRevision;
use flowy_sync::entities::grid::CreateGridSortParams;
use std::convert::TryInto;
use std::sync::Arc;

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
pub struct RepeatedGridSortPB {
    #[pb(index = 1)]
    pub items: Vec<GridSort>,
}

impl std::convert::From<Vec<Arc<GridSortRevision>>> for RepeatedGridSortPB {
    fn from(revs: Vec<Arc<GridSortRevision>>) -> Self {
        RepeatedGridSortPB {
            items: revs.into_iter().map(|rev| rev.as_ref().into()).collect(),
        }
    }
}

impl std::convert::From<Vec<GridSort>> for RepeatedGridSortPB {
    fn from(items: Vec<GridSort>) -> Self {
        Self { items }
    }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct CreateGridSortPayloadPB {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,
}

impl TryInto<CreateGridSortParams> for CreateGridSortPayloadPB {
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateGridSortParams, Self::Error> {
        let field_id = match self.field_id {
            None => None,
            Some(field_id) => Some(NotEmptyStr::parse(field_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(CreateGridSortParams { field_id })
    }
}
