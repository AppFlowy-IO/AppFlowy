use crate::error::Error;
use crate::response::{FlowyResponse, ResponseData, StatusCode};

macro_rules! static_response {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> FlowyResponseBuilder {
            FlowyResponseBuilder::new($status)
        }
    };
}

pub struct FlowyResponseBuilder<T = ResponseData> {
    pub data: T,
    pub status: StatusCode,
    pub error: Option<Error>,
}

impl FlowyResponseBuilder {
    pub fn new(status: StatusCode) -> Self {
        FlowyResponseBuilder {
            data: ResponseData::None,
            status,
            error: None,
        }
    }

    pub fn data<D: std::convert::Into<ResponseData>>(mut self, data: D) -> Self {
        self.data = data.into();
        self
    }

    pub fn error(mut self, error: Option<Error>) -> Self {
        self.error = error;
        self
    }

    pub fn build(self) -> FlowyResponse {
        FlowyResponse {
            data: self.data,
            status: self.status,
            error: self.error,
        }
    }

    static_response!(Ok, StatusCode::Success);
}
