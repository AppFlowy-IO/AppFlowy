use std::cmp::Ordering;
use std::collections::BinaryHeap;
use std::fmt::Debug;
use std::marker::PhantomData;
use std::ops::{Deref, DerefMut};
use std::sync::{Arc, Weak};

use tokio::sync::watch;

use lib_infra::async_trait::async_trait;

pub trait RequestPayload: Clone + Ord {}

#[derive(Debug, Eq, PartialEq, Clone)]
pub enum RequestState {
  Pending,
  Processing,
  Done,
}

#[derive(Debug)]
pub struct PendingRequest<Payload> {
  pub payload: Payload,
  pub state: RequestState,
}

impl<Payload> PendingRequest<Payload> {
  pub fn new(payload: Payload) -> Self {
    Self {
      payload,
      state: RequestState::Pending,
    }
  }

  #[allow(dead_code)]
  pub fn state(&self) -> &RequestState {
    &self.state
  }

  pub fn set_state(&mut self, new_state: RequestState)
  where
    Payload: Debug,
  {
    if self.state != new_state {
      // tracing::trace!(
      //   "PgRequest {:?} from {:?} to {:?}",
      //   self.payload,
      //   self.state,
      //   new_state,
      // );
      self.state = new_state;
    }
  }

  pub fn is_processing(&self) -> bool {
    self.state == RequestState::Processing
  }

  pub fn is_done(&self) -> bool {
    self.state == RequestState::Done
  }
}

impl<Payload> Clone for PendingRequest<Payload>
where
  Payload: Clone + Debug,
{
  fn clone(&self) -> Self {
    Self {
      payload: self.payload.clone(),
      state: self.state.clone(),
    }
  }
}

pub(crate) struct RequestQueue<Payload>(BinaryHeap<PendingRequest<Payload>>);

impl<Payload> RequestQueue<Payload>
where
  Payload: Ord,
{
  pub(crate) fn new() -> Self {
    Self(BinaryHeap::new())
  }
}

impl<Payload> Deref for RequestQueue<Payload>
where
  Payload: Ord,
{
  type Target = BinaryHeap<PendingRequest<Payload>>;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl<Payload> DerefMut for RequestQueue<Payload>
where
  Payload: Ord,
{
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

impl<Payload> Eq for PendingRequest<Payload> where Payload: Eq {}

impl<Payload> PartialEq for PendingRequest<Payload>
where
  Payload: PartialEq,
{
  fn eq(&self, other: &Self) -> bool {
    self.payload == other.payload
  }
}

impl<Payload> PartialOrd for PendingRequest<Payload>
where
  Payload: PartialOrd + Ord,
{
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
    Some(self.cmp(other))
  }
}

impl<Payload> Ord for PendingRequest<Payload>
where
  Payload: Ord,
{
  fn cmp(&self, other: &Self) -> Ordering {
    self.payload.cmp(&other.payload)
  }
}

#[async_trait]
pub trait RequestHandler<Payload>: Send + Sync + 'static {
  async fn prepare_request(&self) -> Option<PendingRequest<Payload>>;
  async fn handle_request(&self, request: PendingRequest<Payload>) -> Option<()>;
  fn notify(&self);
}

#[async_trait]
impl<T, Payload> RequestHandler<Payload> for Arc<T>
where
  T: RequestHandler<Payload>,
  Payload: 'static + Send + Sync,
{
  async fn prepare_request(&self) -> Option<PendingRequest<Payload>> {
    (**self).prepare_request().await
  }

  async fn handle_request(&self, request: PendingRequest<Payload>) -> Option<()> {
    (**self).handle_request(request).await
  }

  fn notify(&self) {
    (**self).notify()
  }
}

pub struct RequestRunner<Payload>(PhantomData<Payload>);
impl<Payload> RequestRunner<Payload>
where
  Payload: 'static + Send + Sync,
{
  pub async fn run(
    mut notifier: watch::Receiver<bool>,
    handler: Weak<dyn RequestHandler<Payload>>,
  ) {
    if let Some(handler) = handler.upgrade() {
      handler.notify();
    }
    loop {
      // stops the runner if the notifier was closed.
      if notifier.changed().await.is_err() {
        break;
      }

      // stops the runner if the value of notifier is `true`
      if *notifier.borrow() {
        break;
      }

      if let Some(handler) = handler.upgrade() {
        if let Some(request) = handler.prepare_request().await {
          if request.is_done() {
            handler.notify();
            continue;
          }

          if request.is_processing() {
            continue;
          }

          let _ = handler.handle_request(request).await;
          handler.notify();
        }
      } else {
        break;
      }
    }
  }
}
