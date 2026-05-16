use std::any::Any;

use anyhow::Result;

#[derive(Debug)]
pub struct BoxAny(Box<dyn Any + Send + Sync + 'static>);

impl BoxAny {
  pub fn new<T>(value: T) -> Self
  where
    T: Send + Sync + 'static,
  {
    Self(Box::new(value))
  }

  pub fn cloned<T>(&self) -> Option<T>
  where
    T: Clone + 'static,
  {
    self.0.downcast_ref::<T>().cloned()
  }

  pub fn unbox_or_default<T>(self) -> T
  where
    T: Default + 'static,
  {
    match self.0.downcast::<T>() {
      Ok(value) => *value,
      Err(_) => T::default(),
    }
  }

  pub fn unbox_or_error<T>(self) -> Result<T>
  where
    T: 'static,
  {
    match self.0.downcast::<T>() {
      Ok(value) => Ok(*value),
      Err(e) => Err(anyhow::anyhow!(
        "downcast error to {} failed: {:?}",
        std::any::type_name::<T>(),
        e
      )),
    }
  }

  pub fn unbox_or_none<T>(self) -> Option<T>
  where
    T: 'static,
  {
    match self.0.downcast::<T>() {
      Ok(value) => Some(*value),
      Err(_) => None,
    }
  }

  #[allow(dead_code)]
  pub fn downcast_ref<T: 'static>(&self) -> Option<&T> {
    self.0.downcast_ref()
  }
}
