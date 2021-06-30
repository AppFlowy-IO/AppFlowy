use std::{
    any::{Any, TypeId},
    collections::HashMap,
};

#[derive(Default)]
pub struct DataContainer {
    map: HashMap<TypeId, Box<dyn Any>>,
}

impl DataContainer {
    #[inline]
    pub fn new() -> DataContainer {
        DataContainer {
            map: HashMap::default(),
        }
    }

    pub fn insert<T: 'static>(&mut self, val: T) -> Option<T> {
        self.map
            .insert(TypeId::of::<T>(), Box::new(val))
            .and_then(downcast_owned)
    }

    pub fn remove<T: 'static>(&mut self) -> Option<T> { self.map.remove(&TypeId::of::<T>()).and_then(downcast_owned) }

    pub fn get<T: 'static>(&self) -> Option<&T> {
        self.map.get(&TypeId::of::<T>()).and_then(|boxed| boxed.downcast_ref())
    }

    pub fn get_mut<T: 'static>(&mut self) -> Option<&mut T> {
        self.map
            .get_mut(&TypeId::of::<T>())
            .and_then(|boxed| boxed.downcast_mut())
    }

    pub fn contains<T: 'static>(&self) -> bool { self.map.contains_key(&TypeId::of::<T>()) }

    pub fn extend(&mut self, other: DataContainer) { self.map.extend(other.map); }
}

fn downcast_owned<T: 'static>(boxed: Box<dyn Any>) -> Option<T> { boxed.downcast().ok().map(|boxed| *boxed) }
