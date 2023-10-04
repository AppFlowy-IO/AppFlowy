use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DateQueryPB {
  #[pb(index = 1)]
  pub query: String,
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct DateResultPB {
  #[pb(index = 1)]
  pub date: String,
}
