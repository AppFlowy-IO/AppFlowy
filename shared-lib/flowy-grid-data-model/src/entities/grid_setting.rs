use crate::entities::{
    CreateGridFilterParams, CreateGridFilterPayload, CreateGridGroupParams, CreateGridGroupPayload,
    CreateGridSortParams, CreateGridSortPayload, RepeatedGridFilter, RepeatedGridGroup, RepeatedGridSort,
};
use crate::parser::NotEmptyStr;
use crate::revision::{GridLayoutRevision, GridSettingRevision};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error_code::ErrorCode;
use std::collections::HashMap;
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSetting {
    #[pb(index = 1)]
    pub filters_by_layout_ty: HashMap<String, RepeatedGridFilter>,

    #[pb(index = 2)]
    pub groups_by_layout_ty: HashMap<String, RepeatedGridGroup>,

    #[pb(index = 3)]
    pub sorts_by_layout_ty: HashMap<String, RepeatedGridSort>,
}

impl std::convert::From<&GridSettingRevision> for GridSetting {
    fn from(rev: &GridSettingRevision) -> Self {
        let filters_by_layout_ty: HashMap<String, RepeatedGridFilter> = rev
            .filter
            .iter()
            .map(|(layout_rev, filter_revs)| (layout_rev.to_string(), filter_revs.into()))
            .collect();

        let groups_by_layout_ty: HashMap<String, RepeatedGridGroup> = rev
            .group
            .iter()
            .map(|(layout_rev, group_revs)| (layout_rev.to_string(), group_revs.into()))
            .collect();

        let sorts_by_layout_ty: HashMap<String, RepeatedGridSort> = rev
            .sort
            .iter()
            .map(|(layout_rev, sort_revs)| (layout_rev.to_string(), sort_revs.into()))
            .collect();

        GridSetting {
            filters_by_layout_ty,
            groups_by_layout_ty,
            sorts_by_layout_ty,
        }
    }
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

impl std::convert::From<GridLayoutRevision> for GridLayoutType {
    fn from(rev: GridLayoutRevision) -> Self {
        match rev {
            GridLayoutRevision::Table => GridLayoutType::Table,
            GridLayoutRevision::Board => GridLayoutType::Board,
        }
    }
}

impl std::convert::From<GridLayoutType> for GridLayoutRevision {
    fn from(layout: GridLayoutType) -> Self {
        match layout {
            GridLayoutType::Table => GridLayoutRevision::Table,
            GridLayoutType::Board => GridLayoutRevision::Board,
        }
    }
}

#[derive(Default, ProtoBuf)]
pub struct GridSettingChangesetPayload {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub layout_type: GridLayoutType,

    #[pb(index = 3, one_of)]
    pub insert_filter: Option<CreateGridFilterPayload>,

    #[pb(index = 4, one_of)]
    pub delete_filter: Option<String>,

    #[pb(index = 5, one_of)]
    pub insert_group: Option<CreateGridGroupPayload>,

    #[pb(index = 6, one_of)]
    pub delete_group: Option<String>,

    #[pb(index = 7, one_of)]
    pub insert_sort: Option<CreateGridSortPayload>,

    #[pb(index = 8, one_of)]
    pub delete_sort: Option<String>,
}

pub struct GridSettingChangesetParams {
    pub grid_id: String,
    pub layout_type: GridLayoutType,
    pub insert_filter: Option<CreateGridFilterParams>,
    pub delete_filter: Option<String>,
    pub insert_group: Option<CreateGridGroupParams>,
    pub delete_group: Option<String>,
    pub insert_sort: Option<CreateGridSortParams>,
    pub delete_sort: Option<String>,
}

impl TryInto<GridSettingChangesetParams> for GridSettingChangesetPayload {
    type Error = ErrorCode;

    fn try_into(self) -> Result<GridSettingChangesetParams, Self::Error> {
        let view_id = NotEmptyStr::parse(self.grid_id)
            .map_err(|_| ErrorCode::FieldIdIsEmpty)?
            .0;

        let insert_filter = match self.insert_filter {
            None => None,
            Some(payload) => Some(payload.try_into()?),
        };

        let delete_filter = match self.delete_filter {
            None => None,
            Some(filter_id) => Some(NotEmptyStr::parse(filter_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        let insert_group = match self.insert_group {
            Some(payload) => Some(payload.try_into()?),
            None => None,
        };

        let delete_group = match self.delete_group {
            None => None,
            Some(filter_id) => Some(NotEmptyStr::parse(filter_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        let insert_sort = match self.insert_sort {
            None => None,
            Some(payload) => Some(payload.try_into()?),
        };

        let delete_sort = match self.delete_sort {
            None => None,
            Some(filter_id) => Some(NotEmptyStr::parse(filter_id).map_err(|_| ErrorCode::FieldIdIsEmpty)?.0),
        };

        Ok(GridSettingChangesetParams {
            grid_id: view_id,
            layout_type: self.layout_type,
            insert_filter,
            delete_filter,
            insert_group,
            delete_group,
            insert_sort,
            delete_sort,
        })
    }
}
