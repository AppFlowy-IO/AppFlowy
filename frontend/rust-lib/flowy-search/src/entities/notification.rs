use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

use super::SearchResultPB;

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct SearchResultNotificationPB {
  #[pb(index = 1)]
  pub items: Vec<SearchResultPB>,

  #[pb(index = 2)]
  pub sends: u64,

  #[pb(index = 3, one_of)]
  pub channel: Option<String>,
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
