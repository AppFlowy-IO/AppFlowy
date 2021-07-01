use crate::{
    error::SystemError,
    response::{data::ResponseData, EventResponse, StatusCode},
};

macro_rules! static_response {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> ResponseBuilder { ResponseBuilder::new($status) }
    };
}

pub struct ResponseBuilder<T = ResponseData> {
    pub data: T,
    pub status: StatusCode,
    pub error: Option<SystemError>,
}

impl ResponseBuilder {
    pub fn new(status: StatusCode) -> Self {
        ResponseBuilder {
            data: ResponseData::None,
            status,
            error: None,
        }
    }

    pub fn data<D: std::convert::Into<ResponseData>>(mut self, data: D) -> Self {
        self.data = data.into();
        self
    }

    pub fn error(mut self, error: SystemError) -> Self {
        self.error = Some(error);
        self
    }

    pub fn build(self) -> EventResponse {
        EventResponse {
            data: self.data,
            status: self.status,
            error: self.error,
        }
    }

    static_response!(Ok, StatusCode::Ok);
    static_response!(Err, StatusCode::Err);
}
