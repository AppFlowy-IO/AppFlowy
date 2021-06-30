pub enum PayloadError {}

// TODO: support stream data
#[derive(Clone, Debug)]
pub enum Payload {
    None,
    Bytes(Vec<u8>),
}
