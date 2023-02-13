use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::Arc;

#[async_trait]
pub trait RefCountValue {
  async fn did_remove(&self) {}
}

struct RefCountHandler<T> {
  ref_count: usize,
  inner: T,
}

impl<T> RefCountHandler<T> {
  pub fn new(inner: T) -> Self {
    Self {
      ref_count: 1,
      inner,
    }
  }

  pub fn increase_ref_count(&mut self) {
    self.ref_count += 1;
  }
}

pub struct RefCountHashMap<T>(HashMap<String, RefCountHandler<T>>);

impl<T> std::default::Default for RefCountHashMap<T> {
  fn default() -> Self {
    Self(HashMap::new())
  }
}

impl<T> RefCountHashMap<T>
where
  T: Clone + Send + Sync + RefCountValue + 'static,
{
  pub fn new() -> Self {
    Self::default()
  }

  pub fn get(&self, key: &str) -> Option<T> {
    self.0.get(key).map(|handler| handler.inner.clone())
  }

  pub fn values(&self) -> Vec<T> {
    self
      .0
      .values()
      .map(|value| value.inner.clone())
      .collect::<Vec<T>>()
  }

  pub fn insert(&mut self, key: String, value: T) {
    if let Some(handler) = self.0.get_mut(&key) {
      handler.increase_ref_count();
    } else {
      let handler = RefCountHandler::new(value);
      self.0.insert(key, handler);
    }
  }

  pub async fn remove(&mut self, key: &str) {
    let mut should_remove = false;
    if let Some(value) = self.0.get_mut(key) {
      if value.ref_count > 0 {
        value.ref_count -= 1;
      }
      should_remove = value.ref_count == 0;
    }

    if should_remove {
      if let Some(handler) = self.0.remove(key) {
        tokio::spawn(async move {
          handler.inner.did_remove().await;
        });
      }
    }
  }
}

#[async_trait]
impl<T> RefCountValue for Arc<T>
where
  T: RefCountValue + Sync + Send,
{
  async fn did_remove(&self) {
    (**self).did_remove().await
  }
}
