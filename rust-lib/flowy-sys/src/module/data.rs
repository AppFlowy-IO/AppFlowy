use crate::{
    error::SystemError,
    request::{payload::Payload, EventRequest, FromRequest},
    util::ready::Ready,
};
use std::{ops::Deref, sync::Arc};

pub struct ModuleData<T: ?Sized>(Arc<T>);

impl<T> ModuleData<T> {
    pub fn new(data: T) -> Self { ModuleData(Arc::new(data)) }

    pub fn get_ref(&self) -> &T { self.0.as_ref() }
}

impl<T: ?Sized> Deref for ModuleData<T> {
    type Target = Arc<T>;

    fn deref(&self) -> &Arc<T> { &self.0 }
}

impl<T: ?Sized> Clone for ModuleData<T> {
    fn clone(&self) -> ModuleData<T> { ModuleData(self.0.clone()) }
}

impl<T: ?Sized> From<Arc<T>> for ModuleData<T> {
    fn from(arc: Arc<T>) -> Self { ModuleData(arc) }
}

impl<T: ?Sized + 'static> FromRequest for ModuleData<T> {
    type Error = SystemError;
    type Future = Ready<Result<Self, SystemError>>;

    #[inline]
    fn from_request(_req: &EventRequest, _: &mut Payload) -> Self::Future { unimplemented!() }
}
