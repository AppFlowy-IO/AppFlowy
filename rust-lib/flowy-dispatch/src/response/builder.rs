use crate::{
    errors::DispatchError,
    request::Payload,
    response::{EventResponse, StatusCode},
};

macro_rules! static_response {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> ResponseBuilder { ResponseBuilder::new($status) }
    };
}

pub struct ResponseBuilder<T = Payload> {
    pub payload: T,
    pub status: StatusCode,
    pub error: Option<DispatchError>,
}

impl ResponseBuilder {
    pub fn new(status: StatusCode) -> Self {
        ResponseBuilder {
            payload: Payload::None,
            status,
            error: None,
        }
    }

    pub fn data<D: std::convert::Into<Payload>>(mut self, data: D) -> Self {
        self.payload = data.into();
        self
    }

    pub fn error(mut self, error: DispatchError) -> Self {
        self.error = Some(error);
        self
    }

    pub fn build(self) -> EventResponse {
        EventResponse {
            payload: self.payload,
            status_code: self.status,
            error: self.error,
        }
    }

    static_response!(Ok, StatusCode::Ok);
    static_response!(Err, StatusCode::Err);
}
