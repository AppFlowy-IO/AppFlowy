use flowy_derive::ProtoBuf;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct RelationFilterPB {
  #[pb(index = 1)]
  pub condition: i64,
}

impl From<(u8, String)> for RelationFilterPB {
  fn from(_value: (u8, String)) -> Self {
    RelationFilterPB { condition: 0 }
  }
}
