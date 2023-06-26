use std::cmp::Ordering;
use std::collections::BinaryHeap;
use std::fmt::Debug;
use std::ops::{Deref, DerefMut};

pub trait RequestPayload: Clone + Ord {}

#[derive(Debug, Eq, PartialEq, Clone)]
pub enum RequestState {
  Pending,
  Processing,
  Done,
  Timeout,
}

#[derive(Debug)]
pub struct PendingRequest<Payload> {
  payload: Payload,
  state: RequestState,
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
