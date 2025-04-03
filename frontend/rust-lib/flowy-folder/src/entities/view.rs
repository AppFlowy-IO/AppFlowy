use client_api::entity::workspace_dto::{
  CreatePageParams, CreateSpaceParams, DuplicatePageParams, FavoriteFolderView, FavoritePageParams,
  FolderView, MovePageParams, RecentFolderView, SpacePermission, TrashFolderView, UpdatePageParams,
  UpdateSpaceParams,
};
use collab_folder::{View, ViewIcon, ViewLayout};
use std::collections::HashMap;
use std::convert::TryInto;
use std::ops::{Deref, DerefMut};
use std::sync::Arc;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_error::ErrorCode;
use flowy_folder_pub::cloud::gen_view_id;

use crate::entities::icon::ViewIconPB;
use crate::entities::parser::view::{ViewIdentify, ViewName, ViewThumbnail};
use crate::notification::FolderNotificationPayload;
use crate::view_operation::ViewData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ChildViewUpdatePB {
  #[pb(index = 1)]
  pub parent_view_id: String,

  #[pb(index = 2)]
  pub create_child_views: Vec<ViewPB>,

  #[pb(index = 3)]
  pub delete_child_views: Vec<String>,

  #[pb(index = 4)]
  pub update_child_views: Vec<ViewPB>,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewPB {
  #[pb(index = 1)]
  pub id: String,

  /// The parent view id of the view.
  /// Each view should have a parent view except the orphan view.
  #[pb(index = 2)]
  pub parent_view_id: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4)]
  pub create_time: i64,

  /// Each view can have multiple child views.
  #[pb(index = 5)]
  pub child_views: Vec<ViewPB>,

  /// The layout of the view. It will be used to determine how the view should be rendered.
  #[pb(index = 6)]
  pub layout: ViewLayoutPB,

  /// The icon of the view.
  #[pb(index = 7, one_of)]
  pub icon: Option<ViewIconPB>,

  #[pb(index = 8)]
  pub is_favorite: bool,

  #[pb(index = 9, one_of)]
  pub extra: Option<String>,

  // user_id
  #[pb(index = 10, one_of)]
  pub created_by: Option<i64>,

  // timestamp
  #[pb(index = 11)]
  pub last_edited: i64,

  // user_id
  #[pb(index = 12, one_of)]
  pub last_edited_by: Option<i64>,

  // is_locked
  // If true, the view is locked and cannot be edited.
  #[pb(index = 13, one_of)]
  pub is_locked: Option<bool>,
}

pub fn view_pb_without_child_views(view: View) -> ViewPB {
  ViewPB {
    id: view.id,
    parent_view_id: view.parent_view_id,
    name: view.name,
    create_time: view.created_at,
    child_views: Default::default(),
    layout: view.layout.into(),
    icon: view.icon.clone().map(|icon| icon.into()),
    is_favorite: view.is_favorite,
    extra: view.extra,
    created_by: view.created_by,
    last_edited: view.last_edited_time,
    last_edited_by: view.last_edited_by,
    is_locked: view.is_locked,
  }
}

pub fn view_pb_without_child_views_from_arc(view: Arc<View>) -> ViewPB {
  ViewPB {
    id: view.id.clone(),
    parent_view_id: view.parent_view_id.clone(),
    name: view.name.clone(),
    create_time: view.created_at,
    child_views: Default::default(),
    layout: view.layout.clone().into(),
    icon: view.icon.clone().map(|icon| icon.into()),
    is_favorite: view.is_favorite,
    extra: view.extra.clone(),
    created_by: view.created_by,
    last_edited: view.last_edited_time,
    last_edited_by: view.last_edited_by,
    is_locked: view.is_locked,
  }
}

/// Returns a ViewPB with child views. Only the first level of child views are included.
pub fn view_pb_with_child_views(view: Arc<View>, child_views: Vec<Arc<View>>) -> ViewPB {
  ViewPB {
    id: view.id.clone(),
    parent_view_id: view.parent_view_id.clone(),
    name: view.name.clone(),
    create_time: view.created_at,
    child_views: child_views
      .into_iter()
      .map(|view| view_pb_without_child_views(view.as_ref().clone()))
      .collect(),
    layout: view.layout.clone().into(),
    icon: view.icon.clone().map(|icon| icon.into()),
    is_favorite: view.is_favorite,
    extra: view.extra.clone(),
    created_by: view.created_by,
    last_edited: view.last_edited_time,
    last_edited_by: view.last_edited_by,
    is_locked: view.is_locked,
  }
}

#[derive(Eq, PartialEq, Hash, Debug, ProtoBuf_Enum, Clone, Default)]
pub enum ViewLayoutPB {
  #[default]
  Document = 0,
  Grid = 1,
  Board = 2,
  Calendar = 3,
  Chat = 4,
}

impl ViewLayoutPB {
  pub fn is_database(&self) -> bool {
    matches!(
      self,
      ViewLayoutPB::Grid | ViewLayoutPB::Board | ViewLayoutPB::Calendar
    )
  }
}

impl std::convert::From<ViewLayout> for ViewLayoutPB {
  fn from(rev: ViewLayout) -> Self {
    match rev {
      ViewLayout::Grid => ViewLayoutPB::Grid,
      ViewLayout::Board => ViewLayoutPB::Board,
      ViewLayout::Document => ViewLayoutPB::Document,
      ViewLayout::Calendar => ViewLayoutPB::Calendar,
      ViewLayout::Chat => ViewLayoutPB::Chat,
    }
  }
}

impl From<ViewLayoutPB> for client_api::entity::workspace_dto::ViewLayout {
  fn from(val: ViewLayoutPB) -> Self {
    match val {
      ViewLayoutPB::Grid => client_api::entity::workspace_dto::ViewLayout::Grid,
      ViewLayoutPB::Board => client_api::entity::workspace_dto::ViewLayout::Board,
      ViewLayoutPB::Document => client_api::entity::workspace_dto::ViewLayout::Document,
      ViewLayoutPB::Calendar => client_api::entity::workspace_dto::ViewLayout::Calendar,
      ViewLayoutPB::Chat => client_api::entity::workspace_dto::ViewLayout::Chat,
    }
  }
}

impl From<client_api::entity::workspace_dto::ViewLayout> for ViewLayoutPB {
  fn from(val: client_api::entity::workspace_dto::ViewLayout) -> Self {
    match val {
      client_api::entity::workspace_dto::ViewLayout::Document => ViewLayoutPB::Document,
      client_api::entity::workspace_dto::ViewLayout::Grid => ViewLayoutPB::Grid,
      client_api::entity::workspace_dto::ViewLayout::Board => ViewLayoutPB::Board,
      client_api::entity::workspace_dto::ViewLayout::Calendar => ViewLayoutPB::Calendar,
      client_api::entity::workspace_dto::ViewLayout::Chat => ViewLayoutPB::Chat,
    }
  }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct SectionViewsPB {
  #[pb(index = 1)]
  pub section: ViewSectionPB,

  #[pb(index = 2)]
  pub views: Vec<ViewPB>,
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedViewPB {
  #[pb(index = 1)]
  pub items: Vec<ViewPB>,
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct FolderViewPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3, one_of)]
  pub icon: Option<ViewIconPB>,

  #[pb(index = 4)]
  pub is_space: bool,

  #[pb(index = 5)]
  pub is_private: bool,

  #[pb(index = 6)]
  pub is_published: bool,

  #[pb(index = 7)]
  pub layout: ViewLayoutPB,

  #[pb(index = 8)]
  pub created_at: i64,

  #[pb(index = 9)]
  pub last_edited_time: i64,

  #[pb(index = 10, one_of)]
  pub is_locked: Option<bool>,

  #[pb(index = 11, one_of)]
  pub extra: Option<String>,

  #[pb(index = 12)]
  pub children: Vec<FolderViewPB>,
}

impl From<FolderView> for FolderViewPB {
  fn from(folder_view: FolderView) -> Self {
    FolderViewPB {
      view_id: folder_view.view_id,
      name: folder_view.name,
      icon: folder_view.icon.map(|icon| icon.into()),
      is_space: folder_view.is_space,
      is_private: folder_view.is_private,
      is_published: folder_view.is_published,
      layout: folder_view.layout.into(),
      created_at: folder_view.created_at.timestamp_millis() as i64,
      last_edited_time: folder_view.last_edited_time.timestamp_millis() as i64,
      is_locked: folder_view.is_locked,
      extra: folder_view.extra.map(|extra| extra.to_string()),
      children: folder_view
        .children
        .into_iter()
        .map(|child| child.into())
        .collect(),
    }
  }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct FolderPageNotificationPayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub folder_view: FolderViewPB,
}

impl FolderNotificationPayload for FolderPageNotificationPayloadPB {
  fn workspace_id(&self) -> &str {
    &self.workspace_id
  }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedFavoriteViewPB {
  #[pb(index = 1)]
  pub items: Vec<SectionViewPB>,
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct ReadRecentViewsPB {
  #[pb(index = 1)]
  pub start: u64,

  #[pb(index = 2)]
  pub limit: u64,
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedRecentViewPB {
  #[pb(index = 1)]
  pub items: Vec<SectionViewPB>,
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct SectionViewPB {
  #[pb(index = 1)]
  pub item: ViewPB,
  #[pb(index = 2)]
  pub timestamp: i64,
}

impl std::convert::From<Vec<ViewPB>> for RepeatedViewPB {
  fn from(items: Vec<ViewPB>) -> Self {
    RepeatedViewPB { items }
  }
}

impl Deref for RepeatedViewPB {
  type Target = Vec<ViewPB>;

  fn deref(&self) -> &Self::Target {
    &self.items
  }
}

impl DerefMut for RepeatedViewPB {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.items
  }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedViewIdPB {
  #[pb(index = 1)]
  pub items: Vec<String>,
}

#[derive(Default, ProtoBuf)]
pub struct CreateViewPayloadPB {
  #[pb(index = 1)]
  pub parent_view_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3, one_of)]
  pub thumbnail: Option<String>,

  #[pb(index = 4)]
  pub layout: ViewLayoutPB,

  #[pb(index = 5)]
  pub initial_data: Vec<u8>,

  #[pb(index = 6)]
  pub meta: HashMap<String, String>,

  // Mark the view as current view after creation.
  #[pb(index = 7)]
  pub set_as_current: bool,

  // The index of the view in the parent view.
  // If the index is None or the index is out of range, the view will be appended to the end of the parent view.
  #[pb(index = 8, one_of)]
  pub index: Option<u32>,

  // The section of the view.
  // Only the view in public section will be shown in the shared workspace view list.
  // The view in private section will only be shown in the user's private view list.
  #[pb(index = 9, one_of)]
  pub section: Option<ViewSectionPB>,

  #[pb(index = 10, one_of)]
  pub view_id: Option<String>,

  // The extra data of the view.
  // Refer to the extra field in the collab
  #[pb(index = 11, one_of)]
  pub extra: Option<String>,
}

#[derive(Eq, PartialEq, Hash, Debug, ProtoBuf_Enum, Clone, Default)]
pub enum ViewSectionPB {
  #[default]
  // only support public and private section now.
  Private = 0,
  Public = 1,
}

/// The orphan view is meant to be a view that is not attached to any parent view. By default, this
/// view will not be shown in the view list unless it is attached to a parent view that is shown in
/// the view list.
#[derive(Default, ProtoBuf)]
pub struct CreateOrphanViewPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub layout: ViewLayoutPB,

  #[pb(index = 4)]
  pub initial_data: Vec<u8>,
}

#[derive(Debug, Clone)]
pub struct CreateViewParams {
  pub parent_view_id: String,
  pub name: String,
  pub layout: ViewLayoutPB,
  pub view_id: String,
  pub initial_data: ViewData,
  pub meta: HashMap<String, String>,
  // Mark the view as current view after creation.
  pub set_as_current: bool,
  // The index of the view in the parent view.
  // If the index is None or the index is out of range, the view will be appended to the end of the parent view.
  pub index: Option<u32>,
  // The section of the view.
  pub section: Option<ViewSectionPB>,
  // The icon of the view.
  pub icon: Option<ViewIcon>,
  // The extra data of the view.
  pub extra: Option<String>,
}

impl TryInto<CreateViewParams> for CreateViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateViewParams, Self::Error> {
    let name = ViewName::parse(self.name)?.0;
    let parent_view_id = ViewIdentify::parse(self.parent_view_id)?.0;
    // if view_id is not provided, generate a new view_id
    let view_id = self.view_id.unwrap_or_else(|| gen_view_id().to_string());

    Ok(CreateViewParams {
      parent_view_id,
      name,
      layout: self.layout,
      view_id,
      initial_data: ViewData::Data(self.initial_data.into()),
      meta: self.meta,
      set_as_current: self.set_as_current,
      index: self.index,
      section: self.section,
      icon: None,
      extra: self.extra,
    })
  }
}

impl TryInto<CreateViewParams> for CreateOrphanViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateViewParams, Self::Error> {
    let name = ViewName::parse(self.name)?.0;
    let parent_view_id = ViewIdentify::parse(self.view_id.clone())?.0;

    Ok(CreateViewParams {
      parent_view_id,
      name,
      layout: self.layout,
      view_id: self.view_id,
      initial_data: ViewData::Data(self.initial_data.into()),
      meta: Default::default(),
      set_as_current: false,
      index: None,
      section: None,
      icon: None,
      extra: None,
    })
  }
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct ViewIdPB {
  #[pb(index = 1)]
  pub value: String,
}

impl std::convert::From<&str> for ViewIdPB {
  fn from(value: &str) -> Self {
    ViewIdPB {
      value: value.to_string(),
    }
  }
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct SetPublishNamePB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub new_name: String,
}

#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct DeletedViewPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub index: Option<i32>,
}

impl std::ops::Deref for ViewIdPB {
  type Target = str;

  fn deref(&self) -> &Self::Target {
    &self.value
  }
}

#[derive(Default, ProtoBuf)]
pub struct UpdateViewPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub name: Option<String>,

  #[pb(index = 3, one_of)]
  pub desc: Option<String>,

  #[pb(index = 4, one_of)]
  pub thumbnail: Option<String>,

  #[pb(index = 5, one_of)]
  pub layout: Option<ViewLayoutPB>,

  #[pb(index = 6, one_of)]
  pub is_favorite: Option<bool>,

  #[pb(index = 7, one_of)]
  // this value used to store the extra data with JSON format
  // for document:
  //  - cover: { type: "", value: "" }
  //    - type: "0" represents normal color,
  //            "1" represents gradient color,
  //            "2" represents built-in image,
  //            "3" represents custom image,
  //            "4" represents local image,
  //            "5" represents unsplash image
  //  - line_height_layout: "small" or "normal" or "large"
  //  - font_layout: "small", or "normal", or "large"
  pub extra: Option<String>,
}

#[derive(Clone, Debug)]
pub struct UpdateViewParams {
  pub view_id: String,
  pub name: Option<String>,
  pub desc: Option<String>,
  pub thumbnail: Option<String>,
  pub layout: Option<ViewLayout>,
  pub is_favorite: Option<bool>,
  pub extra: Option<String>,
}

impl TryInto<UpdateViewParams> for UpdateViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<UpdateViewParams, Self::Error> {
    let view_id = ViewIdentify::parse(self.view_id)?.0;

    let name = match self.name {
      None => None,
      Some(name) => Some(ViewName::parse(name)?.0),
    };

    let thumbnail = match self.thumbnail {
      None => None,
      Some(thumbnail) => Some(ViewThumbnail::parse(thumbnail)?.0),
    };

    let is_favorite = self.is_favorite;

    Ok(UpdateViewParams {
      view_id,
      name,
      desc: self.desc,
      thumbnail,
      is_favorite,
      layout: self.layout.map(|ty| ty.into()),
      extra: self.extra,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct MoveViewPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub from: i32,

  #[pb(index = 3)]
  pub to: i32,
}

/// * `view_id` - A string slice that holds the id of the view to be moved.
/// * `new_parent_id` - A string slice that holds the id of the new parent view.
/// * `prev_view_id` - An `Option<String>` that holds the id of the view after which the `view_id` should be positioned.
///
/// If `prev_view_id` is provided, the moved view will be placed right after
/// the view corresponding to `prev_view_id` under the `new_parent_id`.
///
/// If `prev_view_id` is `None`, the moved view will become the first child of the new parent.
#[derive(Default, ProtoBuf)]
pub struct MoveNestedViewPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub new_parent_id: String,

  #[pb(index = 3, one_of)]
  pub prev_view_id: Option<String>,

  #[pb(index = 4, one_of)]
  pub from_section: Option<ViewSectionPB>,

  #[pb(index = 5, one_of)]
  pub to_section: Option<ViewSectionPB>,
}

pub struct MoveViewParams {
  pub view_id: String,
  pub from: usize,
  pub to: usize,
}

impl TryInto<MoveViewParams> for MoveViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveViewParams, Self::Error> {
    let view_id = ViewIdentify::parse(self.view_id)?.0;
    Ok(MoveViewParams {
      view_id,
      from: self.from as usize,
      to: self.to as usize,
    })
  }
}

#[derive(Debug)]
pub struct MoveNestedViewParams {
  pub view_id: String,
  pub new_parent_id: String,
  pub prev_view_id: Option<String>,
  pub from_section: Option<ViewSectionPB>,
  pub to_section: Option<ViewSectionPB>,
}

impl TryInto<MoveNestedViewParams> for MoveNestedViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MoveNestedViewParams, Self::Error> {
    let view_id = ViewIdentify::parse(self.view_id)?.0;
    let new_parent_id = ViewIdentify::parse(self.new_parent_id)?.0;
    let prev_view_id = self.prev_view_id;
    Ok(MoveNestedViewParams {
      view_id,
      new_parent_id,
      prev_view_id,
      from_section: self.from_section,
      to_section: self.to_section,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct UpdateRecentViewPayloadPB {
  #[pb(index = 1)]
  pub view_ids: Vec<String>,

  // If true, the view will be added to the recent view list.
  // If false, the view will be removed from the recent view list.
  #[pb(index = 2)]
  pub add_in_recent: bool,
}

#[derive(Default, ProtoBuf)]
pub struct UpdateViewVisibilityStatusPayloadPB {
  #[pb(index = 1)]
  pub view_ids: Vec<String>,

  #[pb(index = 2)]
  pub is_public: bool,
}

#[derive(Default, ProtoBuf)]
pub struct DuplicateViewPayloadPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2)]
  pub open_after_duplicate: bool,

  #[pb(index = 3)]
  pub include_children: bool,

  // duplicate the view to the specified parent view.
  // if the parent_view_id is None, the view will be duplicated to the same parent view.
  #[pb(index = 4, one_of)]
  pub parent_view_id: Option<String>,

  // The suffix of the duplicated view name.
  // If the suffix is None, the duplicated view will have the same name with (copy) suffix.
  #[pb(index = 5, one_of)]
  pub suffix: Option<String>,

  #[pb(index = 6)]
  pub sync_after_create: bool,
}

#[derive(Debug)]
pub struct DuplicateViewParams {
  pub view_id: String,

  pub open_after_duplicate: bool,

  pub include_children: bool,

  pub parent_view_id: Option<String>,

  pub suffix: Option<String>,

  pub sync_after_create: bool,
}

impl TryInto<DuplicateViewParams> for DuplicateViewPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DuplicateViewParams, Self::Error> {
    let view_id = ViewIdentify::parse(self.view_id)?.0;
    Ok(DuplicateViewParams {
      view_id,
      open_after_duplicate: self.open_after_duplicate,
      include_children: self.include_children,
      parent_view_id: self.parent_view_id,
      suffix: self.suffix,
      sync_after_create: self.sync_after_create,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct CreatePagePayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2, one_of)]
  pub name: Option<String>,

  #[pb(index = 3)]
  pub layout: ViewLayoutPB,

  #[pb(index = 4)]
  pub parent_view_id: String,
  // todo: support page_data
  // #[pb(index = 4, one_of)]
  // pub page_data: Option<serde_json::Value>,
}

impl TryInto<CreatePageParams> for CreatePagePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreatePageParams, Self::Error> {
    let parent_view_id = ViewIdentify::parse(self.parent_view_id)?.0;
    let layout = self.layout.into();
    let name = match self.name {
      Some(name) => Some(ViewName::parse(name)?.0),
      None => None,
    };
    Ok(CreatePageParams {
      name,
      layout,
      parent_view_id,
      page_data: None,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct UpdatePagePayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4, one_of)]
  pub icon: Option<ViewIconPB>,

  #[pb(index = 5, one_of)]
  pub is_locked: Option<bool>,
  // todo: support extra
  // #[pb(index = 4, one_of)]
  // pub extra: Option<String>,
}

impl TryInto<UpdatePageParams> for UpdatePagePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<UpdatePageParams, Self::Error> {
    let name = ViewName::parse(self.name)?.0;
    let is_locked = self.is_locked;
    Ok(UpdatePageParams {
      name,
      icon: self.icon.map(|icon| icon.into()),
      is_locked,
      extra: None,
    })
  }
}

#[derive(Eq, PartialEq, Hash, Debug, ProtoBuf_Enum, Clone, Default)]
pub enum SpacePermissionPB {
  #[default]
  PublicSpace = 0,

  // Note that enum values use C++ scoping rules, meaning that enum values are siblings of their type, not children of it.  Therefore, "Private" must be unique within the global scope, not just within "SpacePermissionPB".
  PrivateSpace = 1,
}

impl From<SpacePermissionPB> for SpacePermission {
  fn from(value: SpacePermissionPB) -> Self {
    match value {
      SpacePermissionPB::PublicSpace => SpacePermission::PublicToAll,
      SpacePermissionPB::PrivateSpace => SpacePermission::Private,
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct CreateSpacePayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub space_permission: SpacePermissionPB,

  #[pb(index = 4)]
  pub space_icon: String,

  #[pb(index = 5)]
  pub space_icon_color: String,
}

impl TryInto<CreateSpaceParams> for CreateSpacePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<CreateSpaceParams, Self::Error> {
    let name = ViewName::parse(self.name)?.0;
    let space_permission = self.space_permission.into();
    Ok(CreateSpaceParams {
      name,
      space_permission,
      space_icon: self.space_icon,
      space_icon_color: self.space_icon_color,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct UpdateSpacePayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub space_id: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4)]
  pub space_permission: SpacePermissionPB,

  #[pb(index = 5)]
  pub space_icon: String,

  #[pb(index = 6)]
  pub space_icon_color: String,
}

impl TryInto<UpdateSpaceParams> for UpdateSpacePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<UpdateSpaceParams, Self::Error> {
    let name = ViewName::parse(self.name)?.0;
    let space_permission = self.space_permission.into();
    Ok(UpdateSpaceParams {
      name,
      space_permission,
      space_icon: self.space_icon,
      space_icon_color: self.space_icon_color,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct MovePageToTrashPayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub view_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct RestorePageFromTrashPayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub view_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct DuplicatePagePayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3, one_of)]
  pub suffix: Option<String>,
}

impl TryInto<DuplicatePageParams> for DuplicatePagePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<DuplicatePageParams, Self::Error> {
    let suffix = self.suffix;
    Ok(DuplicatePageParams { suffix })
  }
}

#[derive(Default, ProtoBuf)]
pub struct MovePagePayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub new_parent_view_id: String,

  #[pb(index = 4, one_of)]
  pub prev_view_id: Option<String>,
}

impl TryInto<MovePageParams> for MovePagePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<MovePageParams, Self::Error> {
    let new_parent_view_id = ViewIdentify::parse(self.new_parent_view_id)?.0;
    let prev_view_id = self.prev_view_id;
    Ok(MovePageParams {
      new_parent_view_id,
      prev_view_id,
    })
  }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedFavoriteFolderViewPB {
  #[pb(index = 1)]
  pub items: Vec<FavoriteFolderViewPB>,
}

#[derive(Default, ProtoBuf)]
pub struct FavoriteFolderViewPB {
  #[pb(index = 1)]
  pub view: FolderViewPB,

  #[pb(index = 2)]
  pub favorited_at: i64,
}

impl From<FavoriteFolderView> for FavoriteFolderViewPB {
  fn from(value: FavoriteFolderView) -> Self {
    FavoriteFolderViewPB {
      view: value.view.into(),
      favorited_at: value.favorited_at.timestamp(),
    }
  }
}

impl From<Vec<FavoriteFolderView>> for RepeatedFavoriteFolderViewPB {
  fn from(values: Vec<FavoriteFolderView>) -> Self {
    let items = values.into_iter().map(|value| value.into()).collect();
    RepeatedFavoriteFolderViewPB { items }
  }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedRecentFolderViewPB {
  #[pb(index = 1)]
  pub items: Vec<RecentFolderViewPB>,
}

#[derive(Default, ProtoBuf)]
pub struct RecentFolderViewPB {
  #[pb(index = 1)]
  pub view: FolderViewPB,

  #[pb(index = 2)]
  pub last_viewed_at: i64,
}

impl From<RecentFolderView> for RecentFolderViewPB {
  fn from(value: RecentFolderView) -> Self {
    RecentFolderViewPB {
      view: value.view.into(),
      last_viewed_at: value.last_viewed_at.timestamp(),
    }
  }
}

impl From<Vec<RecentFolderView>> for RepeatedRecentFolderViewPB {
  fn from(values: Vec<RecentFolderView>) -> Self {
    let items = values.into_iter().map(|value| value.into()).collect();
    RepeatedRecentFolderViewPB { items }
  }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedTrashFolderViewPB {
  #[pb(index = 1)]
  pub items: Vec<TrashFolderViewPB>,
}

#[derive(Default, ProtoBuf)]
pub struct TrashFolderViewPB {
  #[pb(index = 1)]
  pub view: FolderViewPB,

  #[pb(index = 2)]
  pub deleted_at: i64,
}

impl From<TrashFolderView> for TrashFolderViewPB {
  fn from(value: TrashFolderView) -> Self {
    TrashFolderViewPB {
      view: value.view.into(),
      deleted_at: value.deleted_at.timestamp(),
    }
  }
}

impl From<Vec<TrashFolderView>> for RepeatedTrashFolderViewPB {
  fn from(values: Vec<TrashFolderView>) -> Self {
    let items = values.into_iter().map(|value| value.into()).collect();
    RepeatedTrashFolderViewPB { items }
  }
}

#[derive(Default, ProtoBuf)]
pub struct GetFavoritePagesPayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct GetRecentPagesPayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct GetTrashPagesPayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct UpdateFavoritePagePayloadPB {
  #[pb(index = 1)]
  pub workspace_id: String,
  #[pb(index = 2)]
  pub view_id: String,
  #[pb(index = 3)]
  pub is_favorite: bool,
  #[pb(index = 4)]
  pub is_pinned: bool,
}

impl TryInto<FavoritePageParams> for UpdateFavoritePagePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<FavoritePageParams, Self::Error> {
    Ok(FavoritePageParams {
      is_favorite: self.is_favorite,
      is_pinned: self.is_pinned,
    })
  }
}
