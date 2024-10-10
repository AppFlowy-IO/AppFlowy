use flowy_derive::ProtoBuf;
use flowy_folder_pub::entities::PublishInfoResponse;

use super::RepeatedViewIdPB;

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

impl From<PublishInfoResponse> for PublishInfoResponsePB {
  fn from(info: PublishInfoResponse) -> Self {
    Self {
      view_id: info.view_id,
      publish_name: info.publish_name,
      namespace: info.namespace,
      publisher_email: todo!(),
      publish_timestamp_sec: todo!(),
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct RepeatedPublishInfoResponsePB {
  #[pb(index = 1)]
  pub items: Vec<PublishInfoResponsePB>,
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
