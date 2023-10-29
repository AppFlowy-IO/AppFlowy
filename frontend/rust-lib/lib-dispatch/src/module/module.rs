use std::sync::Arc;
use std::{
  collections::HashMap,
  fmt,
  fmt::{Debug, Display},
  future::Future,
  hash::Hash,
  pin::Pin,
  task::{Context, Poll},
};

use futures_core::ready;
use nanoid::nanoid;
use pin_project::pin_project;

use crate::dispatcher::AFConcurrent;
use crate::module::AFPluginStateMap;
use crate::prelude::{AFBoxFuture, AFStateMap};
use crate::service::AFPluginHandler;
use crate::{
  errors::{DispatchError, InternalError},
  request::{payload::Payload, AFPluginEventRequest, FromAFPluginRequest},
  response::{AFPluginEventResponse, AFPluginResponder},
  service::{
    factory, AFPluginHandlerService, AFPluginServiceFactory, BoxService, BoxServiceFactory,
    Service, ServiceRequest, ServiceResponse,
  },
};

pub type AFPluginMap = Arc<HashMap<AFPluginEvent, Arc<AFPlugin>>>;
pub(crate) fn as_plugin_map(plugins: Vec<AFPlugin>) -> AFPluginMap {
  let mut plugin_map = HashMap::new();
  plugins.into_iter().for_each(|m| {
    let events = m.events();
    let plugins = Arc::new(m);
    events.into_iter().for_each(|e| {
      plugin_map.insert(e, plugins.clone());
    });
  });
  Arc::new(plugin_map)
}

#[derive(PartialEq, Eq, Hash, Debug, Clone)]
pub struct AFPluginEvent(pub String);

impl<T: Display + Eq + Hash + Debug + Clone> std::convert::From<T> for AFPluginEvent {
  fn from(t: T) -> Self {
    AFPluginEvent(format!("{}", t))
  }
}

/// A plugin is used to handle the events that the plugin can handle.
///
/// When an event is a dispatched by the `AFPluginDispatcher`, the dispatcher will
/// find the corresponding plugin to handle the event. The name of the event must be unique,
/// which means only one handler will get called.
///
pub struct AFPlugin {
  pub name: String,

  /// a list of `AFPluginState` that the plugin registers. The state can be read by the plugin's handler.
  #[cfg(feature = "single_thread")]
  states: std::rc::Rc<std::cell::RefCell<AFPluginStateMap>>,

  #[cfg(not(feature = "single_thread"))]
  states: Arc<AFPluginStateMap>,

  /// Contains a list of factories that are used to generate the services used to handle the passed-in
  /// `ServiceRequest`.
  ///
  event_service_factory: Arc<
    HashMap<AFPluginEvent, BoxServiceFactory<(), ServiceRequest, ServiceResponse, DispatchError>>,
  >,
}

impl std::default::Default for AFPlugin {
  fn default() -> Self {
    Self {
      name: "".to_owned(),
      states: Default::default(),
      event_service_factory: Arc::new(HashMap::new()),
    }
  }
}

impl AFPlugin {
  pub fn new() -> Self {
    AFPlugin::default()
  }

  pub fn name(mut self, s: &str) -> Self {
    self.name = s.to_owned();
    self
  }
  #[cfg(feature = "single_thread")]
  pub fn state<D: AFConcurrent + 'static>(self, data: D) -> Self {
    self.states.borrow_mut().insert(data);
    self
  }

  #[cfg(not(feature = "single_thread"))]
  pub fn state<D: AFConcurrent + 'static>(mut self, data: D) -> Self {
    Arc::get_mut(&mut self.states)
      .unwrap()
      .insert(crate::module::AFPluginState::new(data));
    self
  }

  #[track_caller]
  pub fn event<E, H, T, R>(mut self, event: E, handler: H) -> Self
  where
    H: AFPluginHandler<T, R>,
    T: FromAFPluginRequest + 'static + AFConcurrent,
    <T as FromAFPluginRequest>::Future: AFConcurrent,
    R: Future + AFConcurrent + 'static,
    R::Output: AFPluginResponder + 'static,
    E: Eq + Hash + Debug + Clone + Display,
  {
    let event: AFPluginEvent = event.into();
    if self.event_service_factory.contains_key(&event) {
      panic!("Register duplicate Event: {:?}", &event);
    } else {
      Arc::get_mut(&mut self.event_service_factory)
        .unwrap()
        .insert(event, factory(AFPluginHandlerService::new(handler)));
    }
    self
  }

  pub fn events(&self) -> Vec<AFPluginEvent> {
    self
      .event_service_factory
      .keys()
      .cloned()
      .collect::<Vec<_>>()
  }
}

/// A request that will be passed to the corresponding plugin.
///
/// Each request can carry the payload that will be deserialized into the corresponding data struct.
///
#[derive(Debug, Clone)]
pub struct AFPluginRequest {
  pub id: String,
  pub event: AFPluginEvent,
  pub(crate) payload: Payload,
}

impl AFPluginRequest {
  pub fn new<E>(event: E) -> Self
  where
    E: Into<AFPluginEvent>,
  {
    Self {
      id: nanoid!(6),
      event: event.into(),
      payload: Payload::None,
    }
  }

  pub fn payload<P>(mut self, payload: P) -> Self
  where
    P: Into<Payload>,
  {
    self.payload = payload.into();
    self
  }
}

impl std::fmt::Display for AFPluginRequest {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(f, "{}:{:?}", self.id, self.event)
  }
}

impl AFPluginServiceFactory<AFPluginRequest> for AFPlugin {
  type Response = AFPluginEventResponse;
  type Error = DispatchError;
  type Service = BoxService<AFPluginRequest, Self::Response, Self::Error>;
  type Context = ();
  type Future = AFBoxFuture<'static, Result<Self::Service, Self::Error>>;

  fn new_service(&self, _cfg: Self::Context) -> Self::Future {
    let services = self.event_service_factory.clone();
    let states = self.states.clone();
    Box::pin(async move {
      let service = AFPluginService { services, states };
      Ok(Box::new(service) as Self::Service)
    })
  }
}

pub struct AFPluginService {
  services: Arc<
    HashMap<AFPluginEvent, BoxServiceFactory<(), ServiceRequest, ServiceResponse, DispatchError>>,
  >,
  states: AFStateMap,
}

impl Service<AFPluginRequest> for AFPluginService {
  type Response = AFPluginEventResponse;
  type Error = DispatchError;

  type Future = AFBoxFuture<'static, Result<Self::Response, Self::Error>>;

  fn call(&self, request: AFPluginRequest) -> Self::Future {
    let AFPluginRequest { id, event, payload } = request;
    let states = self.states.clone();
    let request = AFPluginEventRequest::new(id, event, states);

    match self.services.get(&request.event) {
      Some(factory) => {
        let service_fut = factory.new_service(());
        let fut = AFPluginServiceFuture {
          fut: Box::pin(async {
            let service = service_fut.await?;
            let service_req = ServiceRequest::new(request, payload);
            service.call(service_req).await
          }),
        };
        Box::pin(async move { Ok(fut.await.unwrap_or_else(|e| e.into())) })
      },
      None => {
        let msg = format!(
          "Can not find service factory for event: {:?}",
          request.event
        );
        Box::pin(async { Err(InternalError::ServiceNotFound(msg).into()) })
      },
    }
  }
}

#[pin_project]
pub struct AFPluginServiceFuture {
  #[pin]
  fut: AFBoxFuture<'static, Result<ServiceResponse, DispatchError>>,
}

impl Future for AFPluginServiceFuture {
  type Output = Result<AFPluginEventResponse, DispatchError>;

  fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    let (_, response) = ready!(self.as_mut().project().fut.poll(cx))?.into_parts();
    Poll::Ready(Ok(response))
  }
}
