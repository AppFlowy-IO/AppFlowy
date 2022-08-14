use crate::entities::{
    CreateGridFilterPayloadPB, CreateGridGroupPayloadPB, CreateGridSortPayloadPB, DeleteFilterPayloadPB,
    DeleteGroupPayloadPB, RepeatedGridConfigurationFilterPB, RepeatedGridGroupConfigurationPB, RepeatedGridSortPB,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::LayoutRevision;
use flowy_sync::entities::grid::GridSettingChangesetParams;
use std::collections::HashMap;
use std::convert::TryInto;
use strum::IntoEnumIterator;
use strum_macros::EnumIter;

/// [GridSettingPB] defines the setting options for the grid. Such as the filter, group, and sort.
#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridSettingPB {
    #[pb(index = 1)]
    pub layouts: Vec<GridLayoutPB>,

    #[pb(index = 2)]
    pub current_layout_type: Layout,

    #[pb(index = 3)]
    pub filter_configuration_by_field_id: HashMap<String, RepeatedGridConfigurationFilterPB>,

    #[pb(index = 4)]
    pub group_configuration_by_field_id: HashMap<String, RepeatedGridGroupConfigurationPB>,

    #[pb(index = 5)]
    pub sorts_by_field_id: HashMap<String, RepeatedGridSortPB>,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridLayoutPB {
    #[pb(index = 1)]
    ty: Layout,
}

impl GridLayoutPB {
    pub fn all() -> Vec<GridLayoutPB> {
        let mut layouts = vec![];
        for layout_ty in Layout::iter() {
            layouts.push(GridLayoutPB { ty: layout_ty })
        }

        layouts
    }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum, EnumIter)]
#[repr(u8)]
pub enum Layout {
    Table = 0,
    Board = 1,
}

impl std::default::Default for Layout {
    fn default() -> Self {
        Layout::Table
    }
}

impl std::convert::From<LayoutRevision> for Layout {
    fn from(rev: LayoutRevision) -> Self {
        match rev {
            LayoutRevision::Table => Layout::Table,
            LayoutRevision::Board => Layout::Board,
        }
    }
}

impl std::convert::From<Layout> for LayoutRevision {
    fn from(layout: Layout) -> Self {
        match layout {
            Layout::Table => LayoutRevision::Table,
            Layout::Board => LayoutRevision::Board,
        }
    }
}

#[derive(Default, ProtoBuf)]
pub struct GridSettingChangesetPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub layout_type: Layout,

    #[pb(index = 3, one_of)]
    pub insert_filter: Option<CreateGridFilterPayloadPB>,

    #[pb(index = 4, one_of)]
    pub delete_filter: Option<DeleteFilterPayloadPB>,

    #[pb(index = 5, one_of)]
    pub insert_group: Option<CreateGridGroupPayloadPB>,

    #[pb(index = 6, one_of)]
    pub delete_group: Option<DeleteGroupPayloadPB>,

    #[pb(index = 7, one_of)]
    pub insert_sort: Option<CreateGridSortPayloadPB>,

    #[pb(index = 8, one_of)]
    pub delete_sort: Option<String>,
}

impl TryInto<GridSettingChangesetParams> for GridSettingChangesetPayloadPB {
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
            Some(payload) => Some(payload.try_into()?),
        };

        let insert_group = match self.insert_group {
            Some(payload) => Some(payload.try_into()?),
            None => None,
        };

        let delete_group = match self.delete_group {
            Some(payload) => Some(payload.try_into()?),
            None => None,
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
            layout_type: self.layout_type.into(),
            insert_filter,
            delete_filter,
            insert_group,
            delete_group,
            insert_sort,
            delete_sort,
        })
    }
}
