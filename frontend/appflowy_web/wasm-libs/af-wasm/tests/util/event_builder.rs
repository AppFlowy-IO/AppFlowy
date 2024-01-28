use af_wasm::core::AppFlowyWASMCore;
use flowy_error::{internal_error, FlowyError};
use std::rc::Rc;
use std::{
  convert::TryFrom,
  fmt::{Debug, Display},
  hash::Hash,
  sync::Arc,
};

use lib_dispatch::prelude::{
  AFPluginDispatcher, AFPluginEventResponse, AFPluginFromBytes, AFPluginRequest, ToBytes, *,
};

#[derive(Clone)]
pub struct EventBuilder {
  context: TestContext,
}

impl EventBuilder {
  pub fn new(core: Arc<AppFlowyWASMCore>) -> Self {
    Self {
      context: TestContext::new(core),
    }
  }

  pub fn payload<P>(mut self, payload: P) -> Self
  where
    P: ToBytes,
  {
    match payload.into_bytes() {
      Ok(bytes) => {
        let module_request = self.take_request();
        self.context.request = Some(module_request.payload(bytes))
      },
      Err(e) => {
        tracing::error!("Set payload failed: {:?}", e);
      },
    }
    self
  }

  pub fn event<Event>(mut self, event: Event) -> Self
  where
    Event: Eq + Hash + Debug + Clone + Display,
  {
    self.context.request = Some(AFPluginRequest::new(event));
    self
  }

  pub async fn async_send(mut self) -> Self {
    let request = self.take_request();
    let resp = AFPluginDispatcher::async_send(self.dispatch().as_ref(), request).await;
    self.context.response = Some(resp);
    self
  }

  pub fn parse<R>(self) -> R
  where
    R: AFPluginFromBytes,
  {
    let response = self.get_response();
    match response.clone().parse::<R, FlowyError>() {
      Ok(Ok(data)) => data,
      Ok(Err(e)) => {
        panic!(
          "Parser {:?} failed: {:?}, response {:?}",
          std::any::type_name::<R>(),
          e,
          response
        )
      },
      Err(e) => panic!(
        "Dispatch {:?} failed: {:?}, response {:?}",
        std::any::type_name::<R>(),
        e,
        response
      ),
    }
  }

  #[allow(dead_code)]
  pub fn try_parse<R>(self) -> Result<R, FlowyError>
  where
    R: AFPluginFromBytes,
  {
    let response = self.get_response();
    response.parse::<R, FlowyError>().map_err(internal_error)?
  }

  #[allow(dead_code)]
  pub fn error(self) -> Option<FlowyError> {
    let response = self.get_response();
    <AFPluginData<FlowyError>>::try_from(response.payload)
      .ok()
      .map(|data| data.into_inner())
  }

  fn dispatch(&self) -> &Rc<AFPluginDispatcher> {
    &self.context.sdk.event_dispatcher
  }

  fn get_response(&self) -> AFPluginEventResponse {
    self
      .context
      .response
      .as_ref()
      .expect("must call sync_send/async_send first")
      .clone()
  }

  fn take_request(&mut self) -> AFPluginRequest {
    self.context.request.take().expect("must call event first")
  }
}

#[derive(Clone)]
pub struct TestContext {
  pub sdk: Arc<AppFlowyWASMCore>,
  request: Option<AFPluginRequest>,
  response: Option<AFPluginEventResponse>,
}

impl TestContext {
  pub fn new(sdk: Arc<AppFlowyWASMCore>) -> Self {
    Self {
      sdk,
      request: None,
      response: None,
    }
  }
}
