use flowy_derive::ProtoBuf;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct SearchFilterPB {
  #[pb(index = 1, one_of)]
  pub workspace_id: Option<String>,
}
