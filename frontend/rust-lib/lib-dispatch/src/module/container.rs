use std::{
    any::{Any, TypeId},
    collections::HashMap,
};

#[derive(Default, Debug)]
pub struct AFPluginStateMap(HashMap<TypeId, Box<dyn Any + Sync + Send>>);

impl AFPluginStateMap {
    #[inline]
    pub fn new() -> AFPluginStateMap {
        AFPluginStateMap(HashMap::default())
    }

    pub fn insert<T>(&mut self, val: T) -> Option<T>
    where
        T: 'static + Send + Sync,
    {
        self.0.insert(TypeId::of::<T>(), Box::new(val)).and_then(downcast_owned)
    }

    pub fn remove<T>(&mut self) -> Option<T>
    where
        T: 'static + Send + Sync,
    {
        self.0.remove(&TypeId::of::<T>()).and_then(downcast_owned)
    }

    pub fn get<T>(&self) -> Option<&T>
    where
        T: 'static + Send + Sync,
    {
        self.0.get(&TypeId::of::<T>()).and_then(|boxed| boxed.downcast_ref())
    }

    pub fn get_mut<T>(&mut self) -> Option<&mut T>
    where
        T: 'static + Send + Sync,
    {
        self.0
            .get_mut(&TypeId::of::<T>())
            .and_then(|boxed| boxed.downcast_mut())
    }

    pub fn contains<T>(&self) -> bool
    where
        T: 'static + Send + Sync,
    {
        self.0.contains_key(&TypeId::of::<T>())
    }

    pub fn extend(&mut self, other: AFPluginStateMap) {
        self.0.extend(other.0);
    }
}

fn downcast_owned<T: 'static + Send + Sync>(boxed: Box<dyn Any + Send + Sync>) -> Option<T> {
    boxed.downcast().ok().map(|boxed| *boxed)
}
