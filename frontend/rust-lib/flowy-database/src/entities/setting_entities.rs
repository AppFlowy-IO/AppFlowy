use crate::entities::parser::NotEmptyStr;
use crate::entities::{
  AlterFilterParams, AlterFilterPayloadPB, AlterSortParams, AlterSortPayloadPB, DeleteFilterParams,
  DeleteFilterPayloadPB, DeleteGroupParams, DeleteGroupPayloadPB, DeleteSortParams,
  DeleteSortPayloadPB, InsertGroupParams, InsertGroupPayloadPB, RepeatedFilterPB,
  RepeatedGroupConfigurationPB, RepeatedSortPB,
};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use grid_model::LayoutRevision;
use std::convert::TryInto;
use strum::IntoEnumIterator;
use strum_macros::EnumIter;

/// [DatabaseViewSettingPB] defines the setting options for the grid. Such as the filter, group, and sort.
#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct DatabaseViewSettingPB {
  #[pb(index = 1)]
  pub support_layouts: Vec<ViewLayoutPB>,

  #[pb(index = 2)]
  pub current_layout: LayoutTypePB,

  #[pb(index = 3)]
  pub filters: RepeatedFilterPB,

  #[pb(index = 4)]
  pub group_configurations: RepeatedGroupConfigurationPB,

  #[pb(index = 5)]
  pub sorts: RepeatedSortPB,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewLayoutPB {
  #[pb(index = 1)]
  ty: LayoutTypePB,
}

impl ViewLayoutPB {
  pub fn all() -> Vec<ViewLayoutPB> {
    let mut layouts = vec![];
    for layout_ty in LayoutTypePB::iter() {
      layouts.push(ViewLayoutPB { ty: layout_ty })
    }

    layouts
  }
}

#[derive(Debug, Clone, PartialEq, Eq, ProtoBuf_Enum, EnumIter)]
#[repr(u8)]
pub enum LayoutTypePB {
  Grid = 0,
  Board = 1,
  Calendar = 2,
}

impl std::default::Default for LayoutTypePB {
  fn default() -> Self {
    LayoutTypePB::Grid
  }
}

impl std::convert::From<LayoutRevision> for LayoutTypePB {
  fn from(rev: LayoutRevision) -> Self {
    match rev {
      LayoutRevision::Grid => LayoutTypePB::Grid,
      LayoutRevision::Board => LayoutTypePB::Board,
      LayoutRevision::Calendar => LayoutTypePB::Calendar,
    }
  }
}

impl std::convert::From<LayoutTypePB> for LayoutRevision {
  fn from(layout: LayoutTypePB) -> Self {
    match layout {
      LayoutTypePB::Grid => LayoutRevision::Grid,
      LayoutTypePB::Board => LayoutRevision::Board,
      LayoutTypePB::Calendar => LayoutRevision::Calendar,
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct DatabaseSettingChangesetPB {
  #[pb(index = 1)]
  pub database_id: String,

  #[pb(index = 2)]
  pub layout_type: LayoutTypePB,

  #[pb(index = 3, one_of)]
  pub alter_filter: Option<AlterFilterPayloadPB>,

  #[pb(index = 4, one_of)]
  pub delete_filter: Option<DeleteFilterPayloadPB>,

  #[pb(index = 5, one_of)]
  pub insert_group: Option<InsertGroupPayloadPB>,

  #[pb(index = 6, one_of)]
  pub delete_group: Option<DeleteGroupPayloadPB>,

  #[pb(index = 7, one_of)]
  pub alter_sort: Option<AlterSortPayloadPB>,

  #[pb(index = 8, one_of)]
  pub delete_sort: Option<DeleteSortPayloadPB>,
}

impl TryInto<DatabaseSettingChangesetParams> for DatabaseSettingChangesetPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DatabaseSettingChangesetParams, Self::Error> {
    let database_id = NotEmptyStr::parse(self.database_id)
      .map_err(|_| ErrorCode::ViewIdInvalid)?
      .0;

    let insert_filter = match self.alter_filter {
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

    let alert_sort = match self.alter_sort {
      None => None,
      Some(payload) => Some(payload.try_into()?),
    };

    let delete_sort = match self.delete_sort {
      None => None,
      Some(payload) => Some(payload.try_into()?),
    };

    Ok(DatabaseSettingChangesetParams {
      database_id,
      layout_type: self.layout_type.into(),
      insert_filter,
      delete_filter,
      insert_group,
      delete_group,
      alert_sort,
      delete_sort,
    })
  }
}

pub struct DatabaseSettingChangesetParams {
  pub database_id: String,
  pub layout_type: LayoutRevision,
  pub insert_filter: Option<AlterFilterParams>,
  pub delete_filter: Option<DeleteFilterParams>,
  pub insert_group: Option<InsertGroupParams>,
  pub delete_group: Option<DeleteGroupParams>,
  pub alert_sort: Option<AlterSortParams>,
  pub delete_sort: Option<DeleteSortParams>,
}

impl DatabaseSettingChangesetParams {
  pub fn is_filter_changed(&self) -> bool {
    self.insert_filter.is_some() || self.delete_filter.is_some()
  }
}
