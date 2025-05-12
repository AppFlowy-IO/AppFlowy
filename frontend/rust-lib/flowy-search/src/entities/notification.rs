use super::SearchResponsePB;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct SearchStatePB {
  #[pb(index = 1, one_of)]
  pub response: Option<SearchResponsePB>,

  #[pb(index = 2)]
  pub search_id: String,
}

#[derive(ProtoBuf_Enum, Debug, Default)]
pub enum SearchNotification {
  #[default]
  Unknown = 0,
  DidUpdateResults = 1,
}

impl std::convert::From<SearchNotification> for i32 {
  fn from(notification: SearchNotification) -> Self {
    notification as i32
  }
}

impl std::convert::From<i32> for SearchNotification {
  fn from(notification: i32) -> Self {
    match notification {
      1 => SearchNotification::DidUpdateResults,
      _ => SearchNotification::Unknown,
    }
  }
}
