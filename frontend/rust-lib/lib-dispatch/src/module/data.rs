use crate::{
    errors::{DispatchError, InternalError},
    request::{payload::Payload, AFPluginEventRequest, FromAFPluginRequest},
    util::ready::{ready, Ready},
};
use std::{any::type_name, ops::Deref, sync::Arc};

pub struct AFPluginState<T: ?Sized + Send + Sync>(Arc<T>);

impl<T> AFPluginState<T>
where
    T: Send + Sync,
{
    pub fn new(data: T) -> Self {
        AFPluginState(Arc::new(data))
    }

    pub fn get_ref(&self) -> &T {
        self.0.as_ref()
    }
}

impl<T> Deref for AFPluginState<T>
where
    T: ?Sized + Send + Sync,
{
    type Target = Arc<T>;

    fn deref(&self) -> &Arc<T> {
        &self.0
    }
}

impl<T> Clone for AFPluginState<T>
where
    T: ?Sized + Send + Sync,
{
    fn clone(&self) -> AFPluginState<T> {
        AFPluginState(self.0.clone())
    }
}

impl<T> From<Arc<T>> for AFPluginState<T>
where
    T: ?Sized + Send + Sync,
{
    fn from(arc: Arc<T>) -> Self {
        AFPluginState(arc)
    }
}

impl<T> FromAFPluginRequest for AFPluginState<T>
where
    T: ?Sized + Send + Sync + 'static,
{
    type Error = DispatchError;
    type Future = Ready<Result<Self, DispatchError>>;

    #[inline]
    fn from_request(req: &AFPluginEventRequest, _: &mut Payload) -> Self::Future {
        if let Some(state) = req.get_state::<AFPluginState<T>>() {
            ready(Ok(state.clone()))
        } else {
            let msg = format!("Failed to get the plugin state of type: {}", type_name::<T>());
            log::error!("{}", msg,);
            ready(Err(InternalError::Other(msg).into()))
        }
    }
}
