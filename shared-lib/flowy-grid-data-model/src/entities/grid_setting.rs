use crate::parser::{NotEmptyStr, ViewFilterParser, ViewGroupParser, ViewSortParser};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error_code::ErrorCode;
use std::collections::HashMap;
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSetting {
    #[pb(index = 1)]
    pub filter: HashMap<String, GridFilter>,

    #[pb(index = 2)]
    pub group: HashMap<String, GridGroup>,

    #[pb(index = 3)]
    pub sort: HashMap<String, GridSort>,
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum)]
#[repr(u8)]
pub enum GridLayoutType {
    Table = 0,
    Board = 1,
}

impl std::default::Default for GridLayoutType {
    fn default() -> Self {
        GridLayoutType::Table
    }
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridFilter {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridGroup {
    #[pb(index = 1, one_of)]
    pub group_field_id: Option<String>,

    #[pb(index = 2, one_of)]
    pub sub_group_field_id: Option<String>,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSort {
    #[pb(index = 1, one_of)]
    pub field_id: Option<String>,
}

#[derive(Default, ProtoBuf)]
pub struct GridSettingChangesetPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub layout_type: GridLayoutType,

    #[pb(index = 3, one_of)]
    pub filter: Option<GridFilter>,

    #[pb(index = 4, one_of)]
    pub group: Option<GridGroup>,

    #[pb(index = 5, one_of)]
    pub sort: Option<GridSort>,
}

pub struct GridSettingChangesetParams {
    pub view_id: String,
    pub layout_type: GridLayoutType,
    pub filter: Option<GridFilter>,
    pub group: Option<GridGroup>,
    pub sort: Option<GridSort>,
}

impl TryInto<GridSettingChangesetParams> for GridSettingChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridSettingChangesetParams, Self::Error> {
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

        Ok(GridSettingChangesetParams {
            view_id,
            layout_type: self.layout_type,
            filter,
            group,
            sort,
        })
    }
}
