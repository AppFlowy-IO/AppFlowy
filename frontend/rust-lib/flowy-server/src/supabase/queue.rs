use std::cmp::Ordering;
use std::collections::BinaryHeap;
use std::fmt::Debug;
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

impl<Payload> PendingRequest<Payload>
where
  Payload: Clone + Debug,
{
  pub fn new(payload: Payload) -> Self {
    Self {
      payload,
      state: RequestState::Pending,
    }
  }

  pub fn get_payload(&self) -> Payload {
    self.payload.clone()
  }

  pub fn get_mut_payload(&mut self) -> &mut Payload {
    &mut self.payload
  }

  pub fn state(&self) -> &RequestState {
    &self.state
  }

  pub fn set_state(&mut self, new_state: RequestState) {
    self.state = new_state;
  }

  pub fn is_pending(&self) -> bool {
    self.state == RequestState::Pending
  }

  pub fn is_processing(&self) -> bool {
    self.state == RequestState::Processing
  }

  pub fn is_done(&self) -> bool {
    self.state == RequestState::Done
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
pub trait RequestHandler: Send + Sync + 'static {
  async fn process_next_request(&self) -> Option<()>;
  fn notify(&self);
}

#[async_trait]
impl<T> RequestHandler for Arc<T>
where
  T: RequestHandler,
{
  async fn process_next_request(&self) -> Option<()> {
    (**self).process_next_request().await
  }

  fn notify(&self) {
    (**self).notify()
  }
}

pub struct RequestRunner();
impl RequestRunner {
  pub async fn run(mut notifier: watch::Receiver<bool>, server: Weak<dyn RequestHandler>) {
    server.upgrade().unwrap().notify();
    loop {
      // stops the runner if the notifier was closed.
      if notifier.changed().await.is_err() {
        break;
      }

      // stops the runner if the value of notifier is `true`
      if *notifier.borrow() {
        break;
      }

      if let Some(server) = server.upgrade() {
        let _ = server.process_next_request().await;
      } else {
        break;
      }
    }
  }
}
