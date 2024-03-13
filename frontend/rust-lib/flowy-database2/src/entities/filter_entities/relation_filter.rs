use flowy_derive::ProtoBuf;

use crate::services::filter::ParseFilterData;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RelationFilterPB {
  #[pb(index = 1)]
  pub condition: i64,
}

impl ParseFilterData for RelationFilterPB {
  fn parse(_condition: u8, _content: String) -> Self {
    RelationFilterPB { condition: 0 }
  }
}
