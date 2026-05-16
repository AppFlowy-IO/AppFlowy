use std::{any::type_name, ops::Deref, sync::Arc};

use crate::prelude::AFConcurrent;
use crate::{
  errors::{DispatchError, InternalError},
  request::{payload::Payload, AFPluginEventRequest, FromAFPluginRequest},
  util::ready::{ready, Ready},
};

pub struct AFPluginState<T: ?Sized + AFConcurrent>(Arc<T>);

impl<T> AFPluginState<T>
where
  T: AFConcurrent,
{
  pub fn new(data: T) -> Self {
    AFPluginState(Arc::new(data))
  }

  pub fn get_ref(&self) -> &T {
    self.0.as_ref()
  }
}

impl<T> Deref for AFPluginState<T>
where
  T: ?Sized + AFConcurrent,
{
  type Target = Arc<T>;

  fn deref(&self) -> &Arc<T> {
    &self.0
  }
}

impl<T> Clone for AFPluginState<T>
where
  T: ?Sized + AFConcurrent,
{
  fn clone(&self) -> AFPluginState<T> {
    AFPluginState(self.0.clone())
  }
}

impl<T> From<Arc<T>> for AFPluginState<T>
where
  T: ?Sized + AFConcurrent,
{
  fn from(arc: Arc<T>) -> Self {
    AFPluginState(arc)
  }
}

impl<T> FromAFPluginRequest for AFPluginState<T>
where
  T: ?Sized + Send + Sync + 'static,
{
  type Error = DispatchError;
  type Future = Ready<Result<Self, DispatchError>>;

  #[inline]
  fn from_request(req: &AFPluginEventRequest, _: &mut Payload) -> Self::Future {
    if let Some(state) = req.get_state::<AFPluginState<T>>() {
      ready(Ok(state))
    } else {
      let msg = format!(
        "Failed to get the plugin state of type: {}",
        type_name::<T>()
      );
      tracing::error!("{}", msg,);
      ready(Err(InternalError::Other(msg).into()))
    }
  }
}
