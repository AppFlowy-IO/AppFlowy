use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default)]
pub struct FFIResponse {
    #[pb(index = 1)]
    event: String,

    #[pb(index = 2)]
    payload: Vec<u8>,

    #[pb(index = 3)]
    error: String,
}
