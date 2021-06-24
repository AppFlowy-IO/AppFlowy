use std::{
    any::{Any, TypeId},
    collections::HashMap,
    fmt,
    mem,
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
}

fn downcast_owned<T: 'static>(boxed: Box<dyn Any>) -> Option<T> { boxed.downcast().ok().map(|boxed| *boxed) }
