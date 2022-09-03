use crate::entities::{
    CreatGroupParams, CreateFilterParams, CreateGridFilterPayloadPB, CreateGridGroupPayloadPB, DeleteFilterParams,
    DeleteFilterPayloadPB, DeleteGroupParams, DeleteGroupPayloadPB, RepeatedGridFilterConfigurationPB,
    RepeatedGridGroupConfigurationPB,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_grid_data_model::parser::NotEmptyStr;
use flowy_grid_data_model::revision::LayoutRevision;
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
    pub layout_type: GridLayout,

    #[pb(index = 3)]
    pub filter_configurations: RepeatedGridFilterConfigurationPB,

    #[pb(index = 4)]
    pub group_configurations: RepeatedGridGroupConfigurationPB,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct GridLayoutPB {
    #[pb(index = 1)]
    ty: GridLayout,
}

impl GridLayoutPB {
    pub fn all() -> Vec<GridLayoutPB> {
        let mut layouts = vec![];
        for layout_ty in GridLayout::iter() {
            layouts.push(GridLayoutPB { ty: layout_ty })
        }

        layouts
    }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum, EnumIter)]
#[repr(u8)]
pub enum GridLayout {
    Table = 0,
    Board = 1,
}

impl std::default::Default for GridLayout {
    fn default() -> Self {
        GridLayout::Table
    }
}

impl std::convert::From<LayoutRevision> for GridLayout {
    fn from(rev: LayoutRevision) -> Self {
        match rev {
            LayoutRevision::Table => GridLayout::Table,
            LayoutRevision::Board => GridLayout::Board,
        }
    }
}

impl std::convert::From<GridLayout> for LayoutRevision {
    fn from(layout: GridLayout) -> Self {
        match layout {
            GridLayout::Table => LayoutRevision::Table,
            GridLayout::Board => LayoutRevision::Board,
        }
    }
}

#[derive(Default, ProtoBuf)]
pub struct GridSettingChangesetPayloadPB {
    #[pb(index = 1)]
    pub grid_id: String,

    #[pb(index = 2)]
    pub layout_type: GridLayout,

    #[pb(index = 3, one_of)]
    pub insert_filter: Option<CreateGridFilterPayloadPB>,

    #[pb(index = 4, one_of)]
    pub delete_filter: Option<DeleteFilterPayloadPB>,

    #[pb(index = 5, one_of)]
    pub insert_group: Option<CreateGridGroupPayloadPB>,

    #[pb(index = 6, one_of)]
    pub delete_group: Option<DeleteGroupPayloadPB>,
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

        Ok(GridSettingChangesetParams {
            grid_id: view_id,
            layout_type: self.layout_type.into(),
            insert_filter,
            delete_filter,
            insert_group,
            delete_group,
        })
    }
}

pub struct GridSettingChangesetParams {
    pub grid_id: String,
    pub layout_type: LayoutRevision,
    pub insert_filter: Option<CreateFilterParams>,
    pub delete_filter: Option<DeleteFilterParams>,
    pub insert_group: Option<CreatGroupParams>,
    pub delete_group: Option<DeleteGroupParams>,
}

impl GridSettingChangesetParams {
    pub fn is_filter_changed(&self) -> bool {
        self.insert_filter.is_some() || self.delete_filter.is_some()
    }
}
