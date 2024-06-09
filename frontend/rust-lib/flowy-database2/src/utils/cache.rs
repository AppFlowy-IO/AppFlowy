use parking_lot::RwLock;
use std::any::{type_name, Any};
use std::collections::HashMap;
use std::fmt::Debug;
use std::hash::Hash;
use std::sync::Arc;

#[derive(Default, Debug)]
/// The better option is use LRU cache
pub struct AnyTypeCache<TypeValueKey>(HashMap<TypeValueKey, TypeValue>);

impl<TypeValueKey> AnyTypeCache<TypeValueKey>
where
  TypeValueKey: Clone + Hash + Eq,
{
  pub fn new() -> Arc<RwLock<AnyTypeCache<TypeValueKey>>> {
    Arc::new(RwLock::new(AnyTypeCache(HashMap::default())))
  }

  pub fn insert<T>(&mut self, key: &TypeValueKey, val: T) -> Option<T>
  where
    T: 'static + Send + Sync,
  {
    self
      .0
      .insert(key.clone(), TypeValue::new(val))
      .and_then(downcast_owned)
  }

  pub fn remove(&mut self, key: &TypeValueKey) {
    self.0.remove(key);
  }

  pub fn get<T>(&self, key: &TypeValueKey) -> Option<&T>
  where
    T: 'static + Send + Sync,
  {
    self
      .0
      .get(key)
      .and_then(|type_value| type_value.boxed.downcast_ref())
  }

  pub fn get_mut<T>(&mut self, key: &TypeValueKey) -> Option<&mut T>
  where
    T: 'static + Send + Sync,
  {
    self
      .0
      .get_mut(key)
      .and_then(|type_value| type_value.boxed.downcast_mut())
  }

  pub fn contains(&self, key: &TypeValueKey) -> bool {
    self.0.contains_key(key)
  }

  pub fn is_empty(&self) -> bool {
    self.0.is_empty()
  }
}

fn downcast_owned<T: 'static + Send + Sync>(type_value: TypeValue) -> Option<T> {
  type_value.boxed.downcast().ok().map(|boxed| *boxed)
}

#[derive(Debug)]
struct TypeValue {
  boxed: Box<dyn Any + Send + Sync + 'static>,
  #[allow(dead_code)]
  ty: &'static str,
}

impl TypeValue {
  pub fn new<T>(value: T) -> Self
  where
    T: Send + Sync + 'static,
  {
    Self {
      boxed: Box::new(value),
      ty: type_name::<T>(),
    }
  }
}

impl std::ops::Deref for TypeValue {
  type Target = Box<dyn Any + Send + Sync + 'static>;

  fn deref(&self) -> &Self::Target {
    &self.boxed
  }
}

impl std::ops::DerefMut for TypeValue {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.boxed
  }
}
