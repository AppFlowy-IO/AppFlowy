use std::pin::Pin;

use bytes::Bytes;
use futures::Stream;

pub enum PayloadError {}

pub type PayloadStream = Pin<Box<dyn Stream<Item = Result<Bytes, PayloadError>>>>;
pub enum Payload<S = PayloadStream> {
    None,
    Stream(S),
}
