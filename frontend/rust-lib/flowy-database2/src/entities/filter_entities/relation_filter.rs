use flowy_derive::ProtoBuf;

use crate::services::filter::{Filter, FromFilterString};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RelationFilterPB {
  #[pb(index = 1)]
  pub condition: i64,
}

impl FromFilterString for RelationFilterPB {
  fn from_filter(_filter: &Filter) -> Self
  where
    Self: Sized,
  {
    RelationFilterPB { condition: 0 }
  }
}

impl From<&Filter> for RelationFilterPB {
  fn from(_filter: &Filter) -> Self {
    RelationFilterPB { condition: 0 }
  }
}
