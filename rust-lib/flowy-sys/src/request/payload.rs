use std::pin::Pin;

use bytes::Bytes;
use futures::Stream;

pub enum PayloadError {}

// TODO: support stream data
#[derive(Clone, Debug)]
pub enum Payload {
    None,
    Bytes(Vec<u8>),
}
