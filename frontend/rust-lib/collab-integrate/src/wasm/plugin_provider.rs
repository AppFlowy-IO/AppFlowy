use crate::collab_builder::{CollabPluginProviderContext, CollabPluginProviderType};
use collab::preclude::CollabPlugin;
use lib_infra::future::Fut;
use std::rc::Rc;

pub trait CollabCloudPluginProvider: 'static {
  fn provider_type(&self) -> CollabPluginProviderType;

  fn get_plugins(&self, context: CollabPluginProviderContext) -> Vec<Box<dyn CollabPlugin>>;

  fn is_sync_enabled(&self) -> bool;
}

impl<T> CollabCloudPluginProvider for Rc<T>
where
  T: CollabCloudPluginProvider,
{
  fn provider_type(&self) -> CollabPluginProviderType {
    (**self).provider_type()
  }

  fn get_plugins(&self, context: CollabPluginProviderContext) -> Vec<Box<dyn CollabPlugin>> {
    (**self).get_plugins(context)
  }

  fn is_sync_enabled(&self) -> bool {
    (**self).is_sync_enabled()
  }
}
