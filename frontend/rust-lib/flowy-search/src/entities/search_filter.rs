use flowy_derive::ProtoBuf;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchFilterPB {
  #[pb(index = 1)]
  pub workspace_id: String,
}
