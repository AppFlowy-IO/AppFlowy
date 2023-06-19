use crate::FlowyCoreTest;
use flowy_user::errors::FlowyError;
use lib_dispatch::prelude::{
  AFPluginDispatcher, AFPluginEventResponse, AFPluginFromBytes, AFPluginRequest, ToBytes, *,
};
use std::{
  convert::TryFrom,
  fmt::{Debug, Display},
  hash::Hash,
  sync::Arc,
};

#[derive(Clone)]
pub struct EventBuilder {
  context: TestContext,
}

impl EventBuilder {
  pub fn new(sdk: FlowyCoreTest) -> Self {
    Self {
      context: TestContext::new(sdk),
    }
  }

  pub fn payload<P>(mut self, payload: P) -> Self
  where
    P: ToBytes,
  {
    match payload.into_bytes() {
      Ok(bytes) => {
        let module_request = self.get_request();
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

  pub fn sync_send(mut self) -> Self {
    let request = self.get_request();
    let resp = AFPluginDispatcher::sync_send(self.dispatch(), request);
    self.context.response = Some(resp);
    self
  }

  pub async fn async_send(mut self) -> Self {
    let request = self.get_request();
    let resp = AFPluginDispatcher::async_send(self.dispatch(), request).await;
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

  pub fn error(self) -> Option<FlowyError> {
    let response = self.get_response();
    <AFPluginData<FlowyError>>::try_from(response.payload)
      .ok()
      .map(|data| data.into_inner())
  }

  fn dispatch(&self) -> Arc<AFPluginDispatcher> {
    self.context.sdk.dispatcher()
  }

  fn get_response(&self) -> AFPluginEventResponse {
    self
      .context
      .response
      .as_ref()
      .expect("must call sync_send/async_send first")
      .clone()
  }

  fn get_request(&mut self) -> AFPluginRequest {
    self.context.request.take().expect("must call event first")
  }
}

#[derive(Clone)]
pub struct TestContext {
  pub sdk: FlowyCoreTest,
  request: Option<AFPluginRequest>,
  response: Option<AFPluginEventResponse>,
}

impl TestContext {
  pub fn new(sdk: FlowyCoreTest) -> Self {
    Self {
      sdk,
      request: None,
      response: None,
    }
  }
}
