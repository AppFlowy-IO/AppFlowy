use crate::{
    error::SystemError,
    request::FlowyRequest,
    response::{data::ResponseData, Responder},
};

#[derive(Clone, Copy)]
pub enum StatusCode {
    Success,
    Error,
}

pub struct FlowyResponse<T = ResponseData> {
    pub data: T,
    pub status: StatusCode,
    pub error: Option<SystemError>,
}

impl FlowyResponse {
    pub fn new(status: StatusCode) -> Self {
        FlowyResponse {
            data: ResponseData::None,
            status,
            error: None,
        }
    }
}

impl Responder for FlowyResponse {
    #[inline]
    fn respond_to(self, _: &FlowyRequest) -> FlowyResponse { self }
}
