use flowy_derive::ProtoBuf;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct CheckboxTypeOptionPB {
  #[pb(index = 1)]
  pub is_selected: bool,
}
