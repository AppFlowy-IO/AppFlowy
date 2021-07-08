use crate::{
    error::SystemError,
    request::{payload::Payload, EventRequest, FromRequest},
    util::ready::Ready,
};
use std::{ops::Deref, sync::Arc};

pub struct ModuleData<T: ?Sized + Send + Sync>(Arc<T>);

impl<T> ModuleData<T>
where
    T: Send + Sync,
{
    pub fn new(data: T) -> Self { ModuleData(Arc::new(data)) }

    pub fn get_ref(&self) -> &T { self.0.as_ref() }
}

impl<T> Deref for ModuleData<T>
where
    T: ?Sized + Send + Sync,
{
    type Target = Arc<T>;

    fn deref(&self) -> &Arc<T> { &self.0 }
}

impl<T> Clone for ModuleData<T>
where
    T: ?Sized + Send + Sync,
{
    fn clone(&self) -> ModuleData<T> { ModuleData(self.0.clone()) }
}

impl<T> From<Arc<T>> for ModuleData<T>
where
    T: ?Sized + Send + Sync,
{
    fn from(arc: Arc<T>) -> Self { ModuleData(arc) }
}

impl<T> FromRequest for ModuleData<T>
where
    T: ?Sized + Send + Sync + 'static,
{
    type Error = SystemError;
    type Future = Ready<Result<Self, SystemError>>;

    #[inline]
    fn from_request(_req: &EventRequest, _: &mut Payload) -> Self::Future { unimplemented!() }
}
