use std::convert::TryInto;

use bytes::Bytes;

use lib_dispatch::prelude::{AFPluginEventResponse, ResponseBuilder};

use crate::FlowyError;

impl lib_dispatch::Error for FlowyError {
  fn as_response(&self) -> AFPluginEventResponse {
    let bytes: Bytes = self.clone().try_into().unwrap();
    ResponseBuilder::Err().data(bytes).build()
  }
}
