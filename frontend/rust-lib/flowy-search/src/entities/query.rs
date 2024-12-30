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

  /// Used to identify the channel of the search
  ///
  /// This can be used to have multiple search notification listeners in place.
  /// It is up to the client to decide how to handle this.
  ///
  /// If not set, then no channel is used.
  ///
  #[pb(index = 4, one_of)]
  pub channel: Option<String>,
}
