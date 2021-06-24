use crate::response::{FlowyResponse, StatusCode};
use std::cell::RefCell;
use std::fmt;

pub struct Error {
    inner: Box<dyn HandlerError>,
}

impl Error {
    pub fn as_handler_error(&self) -> &dyn HandlerError {
        self.inner.as_ref()
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Display::fmt(&self.inner, f)
    }
}

impl fmt::Debug for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}", &self.inner)
    }
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        None
    }
}

impl From<Error> for FlowyResponse {
    fn from(err: Error) -> Self {
        FlowyResponse::from_error(err)
    }
}

impl From<FlowyResponse> for Error {
    fn from(res: FlowyResponse) -> Error {
        InternalError::from_response("", res).into()
    }
}

/// `Error` for any error that implements `ResponseError`
impl<T: HandlerError + 'static> From<T> for Error {
    fn from(err: T) -> Error {
        Error {
            inner: Box::new(err),
        }
    }
}

pub trait HandlerError: fmt::Debug + fmt::Display {
    fn status_code(&self) -> StatusCode;

    fn as_response(&self) -> FlowyResponse {
        let resp = FlowyResponse::new(self.status_code());
        resp
    }
}

pub struct InternalError<T> {
    inner: T,
    status: InternalErrorType,
}

enum InternalErrorType {
    Status(StatusCode),
    Response(RefCell<Option<FlowyResponse>>),
}

impl<T> InternalError<T> {
    pub fn new(inner: T, status: StatusCode) -> Self {
        InternalError {
            inner,
            status: InternalErrorType::Status(status),
        }
    }

    pub fn from_response(inner: T, response: FlowyResponse) -> Self {
        InternalError {
            inner,
            status: InternalErrorType::Response(RefCell::new(Some(response))),
        }
    }
}

impl<T> fmt::Debug for InternalError<T>
where
    T: fmt::Debug + 'static,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Debug::fmt(&self.inner, f)
    }
}

impl<T> fmt::Display for InternalError<T>
where
    T: fmt::Display + 'static,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Display::fmt(&self.inner, f)
    }
}

impl<T> HandlerError for InternalError<T>
where
    T: fmt::Debug + fmt::Display + 'static,
{
    fn status_code(&self) -> StatusCode {
        match self.status {
            InternalErrorType::Status(st) => st,
            InternalErrorType::Response(ref resp) => {
                if let Some(resp) = resp.borrow().as_ref() {
                    resp.status.clone()
                } else {
                    StatusCode::Error
                }
            }
        }
    }

    fn as_response(&self) -> FlowyResponse {
        panic!()
        // match self.status {
        //     InternalErrorType::Status(st) => {
        //         let mut res = Response::new(st);
        //         let mut buf = BytesMut::new();
        //         let _ = write!(Writer(&mut buf), "{}", self);
        //         res.headers_mut().insert(
        //             header::CONTENT_TYPE,
        //             header::HeaderValue::from_static("text/plain; charset=utf-8"),
        //         );
        //         res.set_body(Body::from(buf))
        //     }
        //     InternalErrorType::Response(ref resp) => {
        //         if let Some(resp) = resp.borrow_mut().take() {
        //             resp
        //         } else {
        //             Response::new(StatusCode::INTERNAL_SERVER_ERROR)
        //         }
        //     }
        // }
    }
}
