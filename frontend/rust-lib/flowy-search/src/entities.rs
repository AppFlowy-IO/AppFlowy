use collab_folder::{IconType, ViewIcon};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchQueryPB {
  #[pb(index = 1)]
  pub search: String,

  #[pb(index = 2, one_of)]
  pub limit: Option<i64>,
}

#[derive(Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedSearchResultPB {
  #[pb(index = 1)]
  pub items: Vec<SearchResultPB>,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct SearchResultPB {
  #[pb(index = 1)]
  pub index_type: IndexTypePB,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub id: String,

  #[pb(index = 4)]
  pub data: String,

  #[pb(index = 5, one_of)]
  pub icon: Option<ResultIconPB>,

  #[pb(index = 6)]
  pub score: f64,
}

impl SearchResultPB {
  pub fn with_score(&self, score: f64) -> Self {
    SearchResultPB {
      index_type: self.index_type.clone(),
      view_id: self.view_id.clone(),
      id: self.id.clone(),
      data: self.data.clone(),
      icon: self.icon.clone(),
      score,
    }
  }
}

#[derive(ProtoBuf_Enum, Clone, Debug, PartialEq, Eq, Default)]
pub enum ResultIconTypePB {
  #[default]
  Emoji = 0,
  Url = 1,
  Icon = 2,
}

impl std::convert::From<ResultIconTypePB> for IconType {
  fn from(rev: ResultIconTypePB) -> Self {
    match rev {
      ResultIconTypePB::Emoji => IconType::Emoji,
      ResultIconTypePB::Url => IconType::Url,
      ResultIconTypePB::Icon => IconType::Icon,
    }
  }
}

impl From<IconType> for ResultIconTypePB {
  fn from(val: IconType) -> Self {
    match val {
      IconType::Emoji => ResultIconTypePB::Emoji,
      IconType::Url => ResultIconTypePB::Url,
      IconType::Icon => ResultIconTypePB::Icon,
    }
  }
}

impl std::convert::From<i64> for ResultIconTypePB {
  fn from(icon_ty: i64) -> Self {
    match icon_ty {
      0 => ResultIconTypePB::Emoji,
      1 => ResultIconTypePB::Url,
      2 => ResultIconTypePB::Icon,
      _ => ResultIconTypePB::Emoji,
    }
  }
}

impl std::convert::From<ResultIconTypePB> for i64 {
  fn from(val: ResultIconTypePB) -> Self {
    match val {
      ResultIconTypePB::Emoji => 0,
      ResultIconTypePB::Url => 1,
      ResultIconTypePB::Icon => 2,
    }
  }
}

#[derive(Default, ProtoBuf, Debug, Clone, PartialEq, Eq)]
pub struct ResultIconPB {
  #[pb(index = 1)]
  pub ty: ResultIconTypePB,

  #[pb(index = 2)]
  pub value: String,
}

impl std::convert::From<ResultIconPB> for ViewIcon {
  fn from(rev: ResultIconPB) -> Self {
    ViewIcon {
      ty: rev.ty.into(),
      value: rev.value,
    }
  }
}

impl From<ViewIcon> for ResultIconPB {
  fn from(val: ViewIcon) -> Self {
    ResultIconPB {
      ty: val.ty.into(),
      value: val.value,
    }
  }
}

#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone)]
pub enum IndexTypePB {
  View = 0,
  DocumentBlock = 1,
  DatabaseRow = 2,
}

impl Default for IndexTypePB {
  fn default() -> Self {
    Self::View
  }
}

impl std::convert::From<IndexTypePB> for i32 {
  fn from(notification: IndexTypePB) -> Self {
    notification as i32
  }
}

impl std::convert::From<i32> for IndexTypePB {
  fn from(notification: i32) -> Self {
    match notification {
      1 => IndexTypePB::View,
      2 => IndexTypePB::DocumentBlock,
      _ => IndexTypePB::DatabaseRow,
    }
  }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
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
