use std::ops::{Deref, DerefMut};

use flowy_derive::ProtoBuf;
use flowy_folder_pub::entities::SearchData;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchRequestPB {
  #[pb(index = 1)]
  pub search: String,

  #[pb(index = 2, one_of)]
  pub limit: Option<i64>,
}

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchDataPB {
  #[pb(index = 1)]
  pub index_type: String,

  #[pb(index = 2)]
  pub view_id: String,

  #[pb(index = 3)]
  pub id: String,

  #[pb(index = 4)]
  pub data: String,
}

impl From<SearchData> for SearchDataPB {
  fn from(value: SearchData) -> Self {
    Self {
      index_type: value.index_type,
      view_id: value.view_id,
      id: value.id,
      data: value.data,
    }
  }
}

#[derive(Eq, PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedSearchDataPB {
  #[pb(index = 1)]
  pub items: Vec<SearchDataPB>,
}

impl std::convert::From<Vec<SearchDataPB>> for RepeatedSearchDataPB {
  fn from(items: Vec<SearchDataPB>) -> Self {
    Self { items }
  }
}

impl Deref for RepeatedSearchDataPB {
  type Target = Vec<SearchDataPB>;

  fn deref(&self) -> &Self::Target {
    &self.items
  }
}

impl DerefMut for RepeatedSearchDataPB {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.items
  }
}
