use crate::{
    error::{InternalError, SystemError},
    request::{unexpected_none_payload, EventRequest, FromRequest, Payload},
    response::{EventResponse, Responder, ResponseBuilder, ToBytes},
    util::ready::{ready, Ready},
};
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

pub trait FromBytes: Sized {
    fn parse_from_bytes(bytes: &Vec<u8>) -> Result<Self, String>;
}

#[cfg(feature = "use_protobuf")]
impl<T> FromBytes for T
where
    // https://stackoverflow.com/questions/62871045/tryfromu8-trait-bound-in-trait
    T: for<'a> std::convert::TryFrom<&'a Vec<u8>, Error = String>,
{
    fn parse_from_bytes(bytes: &Vec<u8>) -> Result<Self, String> { T::try_from(bytes) }
}

#[cfg(feature = "use_serde")]
impl<T> FromBytes for T
where
    T: serde::de::DeserializeOwned + 'static,
{
    fn parse_from_bytes(bytes: &Vec<u8>) -> Result<Self, String> {
        let s = String::from_utf8_lossy(bytes);
        match serde_json::from_str::<T>(s.as_ref()) {
            Ok(data) => Ok(data),
            Err(e) => Err(format!("{:?}", e)),
        }
    }
}

impl<T> FromRequest for Data<T>
where
    T: FromBytes + 'static,
{
    type Error = SystemError;
    type Future = Ready<Result<Self, SystemError>>;

    #[inline]
    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future {
        match payload {
            Payload::None => ready(Err(unexpected_none_payload(req))),
            Payload::Bytes(bytes) => match T::parse_from_bytes(bytes) {
                Ok(data) => ready(Ok(Data(data))),
                Err(e) => ready(Err(InternalError::new(format!("{:?}", e)).into())),
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
            Ok(bytes) => ResponseBuilder::Ok().data(bytes.to_vec()).build(),
            Err(e) => {
                let system_err: SystemError = InternalError::new(format!("{:?}", e)).into();
                system_err.into()
            },
        }
    }
}

impl<T> std::convert::From<T> for Data<T>
where
    T: ToBytes,
{
    fn from(val: T) -> Self { Data(val) }
}

impl<T> std::convert::TryFrom<&Payload> for Data<T>
where
    T: FromBytes,
{
    type Error = String;

    fn try_from(payload: &Payload) -> Result<Data<T>, Self::Error> {
        match payload {
            Payload::None => Err(format!("Expected payload")),
            Payload::Bytes(bytes) => match T::parse_from_bytes(bytes) {
                Ok(data) => Ok(Data(data)),
                Err(e) => Err(e),
            },
        }
    }
}

impl<T> std::convert::TryInto<Payload> for Data<T>
where
    T: ToBytes,
{
    type Error = String;

    fn try_into(self) -> Result<Payload, Self::Error> {
        let inner = self.into_inner();
        let bytes = inner.into_bytes()?;
        Ok(Payload::Bytes(bytes))
    }
}
