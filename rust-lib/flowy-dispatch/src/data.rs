use crate::{
    byte_trait::*,
    errors::{DispatchError, InternalError},
    request::{unexpected_none_payload, EventRequest, FromRequest, Payload},
    response::{EventResponse, Responder, ResponseBuilder},
    util::ready::{ready, Ready},
};
use bytes::Bytes;
use std::ops;

pub struct Data<T>(pub T);

impl<T> Data<T> {
    pub fn into_inner(self) -> T { self.0 }
}

impl<T> ops::Deref for Data<T> {
    type Target = T;

    fn deref(&self) -> &T { &self.0 }
}

impl<T> ops::DerefMut for Data<T> {
    fn deref_mut(&mut self) -> &mut T { &mut self.0 }
}

impl<T> FromRequest for Data<T>
where
    T: FromBytes + 'static,
{
    type Error = DispatchError;
    type Future = Ready<Result<Self, DispatchError>>;

    #[inline]
    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future {
        match payload {
            Payload::None => ready(Err(unexpected_none_payload(req))),
            Payload::Bytes(bytes) => match T::parse_from_bytes(bytes.clone()) {
                Ok(data) => ready(Ok(Data(data))),
                Err(e) => ready(Err(
                    InternalError::DeserializeFromBytes(format!("{}", e)).into()
                )),
            },
        }
    }
}

impl<T> Responder for Data<T>
where
    T: ToBytes,
{
    fn respond_to(self, _request: &EventRequest) -> EventResponse {
        match self.into_inner().into_bytes() {
            Ok(bytes) => ResponseBuilder::Ok().data(bytes).build(),
            Err(e) => e.into(),
        }
    }
}

impl<T> std::convert::TryFrom<&Payload> for Data<T>
where
    T: FromBytes,
{
    type Error = DispatchError;
    fn try_from(payload: &Payload) -> Result<Data<T>, Self::Error> { parse_payload(payload) }
}

impl<T> std::convert::TryFrom<Payload> for Data<T>
where
    T: FromBytes,
{
    type Error = DispatchError;
    fn try_from(payload: Payload) -> Result<Data<T>, Self::Error> { parse_payload(&payload) }
}

fn parse_payload<T>(payload: &Payload) -> Result<Data<T>, DispatchError>
where
    T: FromBytes,
{
    match payload {
        Payload::None => {
            Err(InternalError::UnexpectedNone(format!("Parse fail, expected payload")).into())
        },
        Payload::Bytes(bytes) => {
            let data = T::parse_from_bytes(bytes.clone())?;
            Ok(Data(data))
        },
    }
}

impl<T> std::convert::TryInto<Payload> for Data<T>
where
    T: ToBytes,
{
    type Error = DispatchError;

    fn try_into(self) -> Result<Payload, Self::Error> {
        let inner = self.into_inner();
        let bytes = inner.into_bytes()?;
        Ok(Payload::Bytes(bytes))
    }
}

impl ToBytes for Data<String> {
    fn into_bytes(self) -> Result<Bytes, DispatchError> { Ok(Bytes::from(self.0)) }
}
