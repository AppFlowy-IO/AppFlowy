use crate::response::{FlowyResponse, StatusCode};
use std::{cell::RefCell, fmt};

pub trait Error: fmt::Debug + fmt::Display {
    fn status_code(&self) -> StatusCode;

    fn as_response(&self) -> FlowyResponse { FlowyResponse::new(self.status_code()) }
}

impl<T: Error + 'static> From<T> for SystemError {
    fn from(err: T) -> SystemError { SystemError { inner: Box::new(err) } }
}

pub struct SystemError {
    inner: Box<dyn Error>,
}

impl SystemError {
    pub fn inner_error(&self) -> &dyn Error { self.inner.as_ref() }
}

impl fmt::Display for SystemError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { fmt::Display::fmt(&self.inner, f) }
}

impl fmt::Debug for SystemError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}", &self.inner) }
}

impl std::error::Error for SystemError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> { None }

    fn cause(&self) -> Option<&dyn std::error::Error> { None }
}

impl From<SystemError> for FlowyResponse {
    fn from(err: SystemError) -> Self { err.inner_error().as_response() }
}
