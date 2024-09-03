use flowy_derive::ProtoBuf;
#[derive(Default, ProtoBuf, Clone, Debug)]
pub struct RegisterStreamPB {
  #[pb(index = 1)]
  pub port: i64,
}
