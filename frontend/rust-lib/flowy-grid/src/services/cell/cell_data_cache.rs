use parking_lot::RwLock;
use std::any::{type_name, Any};

use std::collections::HashMap;

use std::fmt::Debug;
use std::hash::Hasher;
use std::sync::Arc;

pub type AtomicCellDataCache = Arc<RwLock<AnyTypeCache>>;
pub type AtomicCellFilterCache = Arc<RwLock<AnyTypeCache>>;
pub type TypeValueKey = u64;

#[derive(Default, Debug)]
pub struct AnyTypeCache(HashMap<TypeValueKey, TypeValue>);

impl AnyTypeCache {
    pub fn new() -> AtomicCellDataCache {
        Arc::new(RwLock::new(AnyTypeCache(HashMap::default())))
    }

    pub fn insert<T>(&mut self, key: &TypeValueKey, val: T) -> Option<T>
    where
        T: 'static + Send + Sync,
    {
        self.0
            .insert(key.to_owned(), TypeValue::new(val))
            .and_then(downcast_owned)
    }

    pub fn remove<T>(&mut self, key: &TypeValueKey) -> Option<T>
    where
        T: 'static + Send + Sync,
    {
        self.0.remove(key).and_then(downcast_owned)
    }

    pub fn get<T>(&self, key: &TypeValueKey) -> Option<&T>
    where
        T: 'static + Send + Sync,
    {
        self.0.get(key).and_then(|type_value| type_value.boxed.downcast_ref())
    }

    pub fn get_mut<T>(&mut self, key: &TypeValueKey) -> Option<&mut T>
    where
        T: 'static + Send + Sync,
    {
        self.0
            .get_mut(key)
            .and_then(|type_value| type_value.boxed.downcast_mut())
    }

    pub fn contains<T>(&self, key: &TypeValueKey) -> bool
    where
        T: 'static + Send + Sync,
    {
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

// #[cfg(test)]
// mod tests {
//     use crate::services::cell::CellDataCache;
//
//     #[test]
//     fn test() {
//         let mut ext = CellDataCache::new();
//         ext.insert("1", "a".to_string());
//         ext.insert("2", 2);
//
//         let a: &String = ext.get("1").unwrap();
//         assert_eq!(a, "a");
//
//         let a: Option<&usize> = ext.get("1");
//         assert!(a.is_none());
//     }
// }
