use collab_folder::{IconType, ViewIcon};
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

use super::IndexTypePB;

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

  #[pb(index = 7)]
  pub workspace_id: String,
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
      workspace_id: self.workspace_id.clone(),
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
