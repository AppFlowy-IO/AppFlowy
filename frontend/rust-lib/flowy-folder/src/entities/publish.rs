use std::collections::HashMap;

use collab_entity::EncodedCollab;
use flowy_derive::ProtoBuf;
use flowy_folder_pub::entities::PublishInfoResponse;

#[derive(Default, ProtoBuf)]
pub struct PublishViewParamsPB {
  #[pb(index = 1)]
  pub view_id: String,
  #[pb(index = 2, one_of)]
  pub publish_name: Option<String>,
}

#[derive(Default, ProtoBuf)]
pub struct UnpublishViewsPayloadPB {
  #[pb(index = 1)]
  pub view_ids: Vec<String>,
}

#[derive(Default, ProtoBuf)]
pub struct PublishInfoResponsePB {
  #[pb(index = 1)]
  pub view_id: String,
  #[pb(index = 2)]
  pub publish_name: String,
  #[pb(index = 3, one_of)]
  pub namespace: Option<String>,
}

impl From<PublishInfoResponse> for PublishInfoResponsePB {
  fn from(info: PublishInfoResponse) -> Self {
    Self {
      view_id: info.view_id,
      publish_name: info.publish_name,
      namespace: info.namespace,
    }
  }
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
