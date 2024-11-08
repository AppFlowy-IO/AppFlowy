use client_api::entity::workspace_dto::{FolderViewMinimal, PublishInfoView};
use client_api::entity::PublishInfo;
use flowy_derive::ProtoBuf;

use super::{RepeatedViewIdPB, ViewIconPB, ViewLayoutPB};

#[derive(Default, ProtoBuf)]
pub struct PublishViewParamsPB {
  #[pb(index = 1)]
  pub view_id: String,

  #[pb(index = 2, one_of)]
  pub publish_name: Option<String>,

  #[pb(index = 3, one_of)]
  pub selected_view_ids: Option<RepeatedViewIdPB>,
}

#[derive(Default, ProtoBuf)]
pub struct UnpublishViewsPayloadPB {
  #[pb(index = 1)]
  pub view_ids: Vec<String>,
}

#[derive(Default, ProtoBuf)]
pub struct PublishInfoViewPB {
  #[pb(index = 1)]
  pub view: FolderViewMinimalPB,
  #[pb(index = 2)]
  pub info: PublishInfoResponsePB,
}

impl From<PublishInfoView> for PublishInfoViewPB {
  fn from(info_view: PublishInfoView) -> Self {
    Self {
      view: info_view.view.into(),
      info: info_view.info.into(),
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct FolderViewMinimalPB {
  #[pb(index = 1)]
  pub view_id: String,
  #[pb(index = 2)]
  pub name: String,
  #[pb(index = 3, one_of)]
  pub icon: Option<ViewIconPB>,
  #[pb(index = 4)]
  pub layout: ViewLayoutPB,
}

impl From<FolderViewMinimal> for FolderViewMinimalPB {
  fn from(view: FolderViewMinimal) -> Self {
    Self {
      view_id: view.view_id,
      name: view.name,
      icon: view.icon.map(Into::into),
      layout: view.layout.into(),
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct PublishInfoResponsePB {
  #[pb(index = 1)]
  pub view_id: String,
  #[pb(index = 2)]
  pub publish_name: String,
  #[pb(index = 3, one_of)]
  pub namespace: Option<String>,
  #[pb(index = 4)]
  pub publisher_email: String,
  #[pb(index = 5)]
  pub publish_timestamp_sec: i64,
}

impl From<PublishInfo> for PublishInfoResponsePB {
  fn from(info: PublishInfo) -> Self {
    Self {
      view_id: info.view_id.to_string(),
      publish_name: info.publish_name,
      namespace: Some(info.namespace),
      publisher_email: info.publisher_email,
      publish_timestamp_sec: info.publish_timestamp.timestamp(),
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedPublishInfoViewPB {
  #[pb(index = 1)]
  pub items: Vec<PublishInfoViewPB>,
}

#[derive(Default, ProtoBuf)]
pub struct SetPublishNamespacePayloadPB {
  #[pb(index = 1)]
  pub new_namespace: String,
}

#[derive(Default, ProtoBuf)]
pub struct PublishNamespacePB {
  #[pb(index = 1)]
  pub namespace: String,
}
