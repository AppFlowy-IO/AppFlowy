use collab_folder::{IconType, ViewIcon};
use derive_builder::Builder;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_folder::entities::ViewIconPB;

#[derive(Debug, Default, ProtoBuf, Builder, Clone)]
#[builder(name = "CreateSearchResultPBArgs")]
#[builder(pattern = "mutable")]
pub struct SearchResponsePB {
  #[pb(index = 1, one_of)]
  #[builder(default)]
  pub search_result: Option<RepeatedSearchResponseItemPB>,

  #[pb(index = 2, one_of)]
  #[builder(default)]
  pub search_summary: Option<RepeatedSearchSummaryPB>,

  #[pb(index = 3, one_of)]
  #[builder(default)]
  pub local_search_result: Option<RepeatedLocalSearchResponseItemPB>,

  #[pb(index = 4)]
  #[builder(default)]
  pub searching: bool,

  #[pb(index = 5)]
  #[builder(default)]
  pub generating_ai_summary: bool,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedSearchSummaryPB {
  #[pb(index = 1)]
  pub items: Vec<SearchSummaryPB>,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct SearchSummaryPB {
  #[pb(index = 1)]
  pub content: String,

  #[pb(index = 2)]
  pub sources: Vec<SearchSourcePB>,

  #[pb(index = 3)]
  pub highlights: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct SearchSourcePB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub display_name: String,

  #[pb(index = 3, one_of)]
  pub icon: Option<ResultIconPB>,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedSearchResponseItemPB {
  #[pb(index = 1)]
  pub items: Vec<SearchResponseItemPB>,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct SearchResponseItemPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub display_name: String,

  #[pb(index = 3, one_of)]
  pub icon: Option<ResultIconPB>,

  #[pb(index = 4)]
  pub workspace_id: String,

  #[pb(index = 5)]
  pub content: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedLocalSearchResponseItemPB {
  #[pb(index = 1)]
  pub items: Vec<LocalSearchResponseItemPB>,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct LocalSearchResponseItemPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub display_name: String,

  #[pb(index = 3, one_of)]
  pub icon: Option<ResultIconPB>,

  #[pb(index = 4)]
  pub workspace_id: String,
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

impl From<ViewIconPB> for ResultIconPB {
  fn from(val: ViewIconPB) -> Self {
    ResultIconPB {
      ty: IconType::from(val.ty).into(),
      value: val.value,
    }
  }
}
