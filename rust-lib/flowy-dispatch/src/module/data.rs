use crate::{
    errors::{DispatchError, InternalError},
    request::{payload::Payload, EventRequest, FromRequest},
    util::ready::{ready, Ready},
};
use std::{any::type_name, ops::Deref, sync::Arc};

pub struct Unit<T: ?Sized + Send + Sync>(Arc<T>);

impl<T> Unit<T>
where
    T: Send + Sync,
{
    pub fn new(data: T) -> Self { Unit(Arc::new(data)) }

    pub fn get_ref(&self) -> &T { self.0.as_ref() }
}

impl<T> Deref for Unit<T>
where
    T: ?Sized + Send + Sync,
{
    type Target = Arc<T>;

    fn deref(&self) -> &Arc<T> { &self.0 }
}

impl<T> Clone for Unit<T>
where
    T: ?Sized + Send + Sync,
{
    fn clone(&self) -> Unit<T> { Unit(self.0.clone()) }
}

impl<T> From<Arc<T>> for Unit<T>
where
    T: ?Sized + Send + Sync,
{
    fn from(arc: Arc<T>) -> Self { Unit(arc) }
}

impl<T> FromRequest for Unit<T>
where
    T: ?Sized + Send + Sync + 'static,
{
    type Error = DispatchError;
    type Future = Ready<Result<Self, DispatchError>>;

    #[inline]
    fn from_request(req: &EventRequest, _: &mut Payload) -> Self::Future {
        if let Some(data) = req.module_data::<Unit<T>>() {
            ready(Ok(data.clone()))
        } else {
            let msg = format!(
                "Failed to get the module data of type: {}",
                type_name::<T>()
            );
            log::error!("{}", msg,);
            ready(Err(InternalError::Other(msg).into()))
        }
    }
}
