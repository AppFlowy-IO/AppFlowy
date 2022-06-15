use crate::parser::{NotEmptyStr, ViewFilterParser, ViewGroupParser, ViewSortParser};
use flowy_derive::ProtoBuf;
use flowy_error_code::ErrorCode;
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewExtData {
    #[pb(index = 1)]
    pub filter: ViewFilter,

    #[pb(index = 2)]
    pub group: ViewGroup,

    #[pb(index = 3)]
    pub sort: ViewSort,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewFilter {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewGroup {
    #[pb(index = 1, one_of)]
    pub group_field_id: Option<String>,

    #[pb(index = 2, one_of)]
    pub sub_group_field_id: Option<String>,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewSort {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,
}

#[derive(Default, ProtoBuf)]
pub struct GridInfoChangesetPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2, one_of)]
    pub filter: Option<ViewFilter>,

    #[pb(index = 3, one_of)]
    pub group: Option<ViewGroup>,

    #[pb(index = 4, one_of)]
    pub sort: Option<ViewSort>,
}

pub struct GridInfoChangesetParams {
    pub view_id: String,
    pub filter: Option<ViewFilter>,
    pub group: Option<ViewGroup>,
    pub sort: Option<ViewSort>,
}

impl TryInto<GridInfoChangesetParams> for GridInfoChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridInfoChangesetParams, Self::Error> {
        let view_id = NotEmptyStr::parse(self.grid_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;

        let filter = match self.filter {
            None => None,
            Some(filter) => Some(ViewFilterParser::parse(filter)?),
        };

        let group = match self.group {
            None => None,
            Some(group) => Some(ViewGroupParser::parse(group)?),
        };

        let sort = match self.sort {
            None => None,
            Some(sort) => Some(ViewSortParser::parse(sort)?),
        };

        Ok(GridInfoChangesetParams {
            view_id,
            filter,
            group,
            sort,
        })
    }
}
