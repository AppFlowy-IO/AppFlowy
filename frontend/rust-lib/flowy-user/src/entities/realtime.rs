use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default, Clone)]
pub struct RealtimePayloadPB {
  #[pb(index = 1)]
  pub(crate) json_str: String,
}
