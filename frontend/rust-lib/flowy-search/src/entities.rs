use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchQueryPB {
  #[pb(index = 1)]
  pub search: String,

  #[pb(index = 2, one_of)]
  pub limit: Option<i64>,
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedSearchResultPB {
  #[pb(index = 1)]
  pub items: Vec<SearchResultPB>,
}

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchResultPB {
  #[pb(index = 1)]
  pub index_type: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub id: String,

  #[pb(index = 4)]
  pub data: String,
}

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchResultNotificationPB {
  #[pb(index = 1)]
  pub items: Vec<SearchResultPB>,

  #[pb(index = 2)]
  pub closed: bool,
}

#[derive(ProtoBuf_Enum, Debug, Default)]
pub enum SearchNotification {
  #[default]
  Unknown = 0,
  DidUpdateResults = 1,
  DidCloseResults = 2,
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
      2 => SearchNotification::DidCloseResults,
      _ => SearchNotification::Unknown,
    }
  }
}
