use flowy_derive::ProtoBuf;
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct URLCellDataPB {
  #[pb(index = 1)]
  pub url: String,

  #[pb(index = 2)]
  pub content: String,
}
