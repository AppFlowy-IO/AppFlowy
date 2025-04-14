use flowy_derive::ProtoBuf;

use super::SearchFilterPB;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchQueryPB {
  #[pb(index = 1)]
  pub search: String,

  #[pb(index = 2, one_of)]
  pub limit: Option<i64>,

  #[pb(index = 3, one_of)]
  pub filter: Option<SearchFilterPB>,

  #[pb(index = 4)]
  pub search_id: String,

  #[pb(index = 5)]
  pub stream_port: i64,
}
