use crate::{
    error::SystemError,
    response::{data::ResponseData, EventResponse, StatusCode},
};

macro_rules! static_response {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> EventResponseBuilder { EventResponseBuilder::new($status) }
    };
}

pub struct EventResponseBuilder<T = ResponseData> {
    pub data: T,
    pub status: StatusCode,
    pub error: Option<SystemError>,
}

impl EventResponseBuilder {
    pub fn new(status: StatusCode) -> Self {
        EventResponseBuilder {
            data: ResponseData::None,
            status,
            error: None,
        }
    }

    pub fn data<D: std::convert::Into<ResponseData>>(mut self, data: D) -> Self {
        self.data = data.into();
        self
    }

    pub fn error(mut self, error: Option<SystemError>) -> Self {
        self.error = error;
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
