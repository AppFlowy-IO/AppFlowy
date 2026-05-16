use crate::{
  request::Payload,
  response::{AFPluginEventResponse, StatusCode},
};

macro_rules! static_response {
  ($name:ident, $status:expr) => {
    #[allow(non_snake_case, missing_docs)]
    pub fn $name() -> ResponseBuilder {
      ResponseBuilder::new($status)
    }
  };
}

pub struct ResponseBuilder<T = Payload> {
  pub payload: T,
  pub status: StatusCode,
}

impl ResponseBuilder {
  pub fn new(status: StatusCode) -> Self {
    ResponseBuilder {
      payload: Payload::None,
      status,
    }
  }

  pub fn data<D: std::convert::Into<Payload>>(mut self, data: D) -> Self {
    self.payload = data.into();
    self
  }

  pub fn build(self) -> AFPluginEventResponse {
    AFPluginEventResponse {
      payload: self.payload,
      status_code: self.status,
    }
  }

  static_response!(Ok, StatusCode::Ok);
  static_response!(Err, StatusCode::Err);
}
