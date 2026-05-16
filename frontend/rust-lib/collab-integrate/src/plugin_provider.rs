use collab::preclude::CollabPlugin;

use crate::collab_builder::{CollabPluginProviderContext, CollabPluginProviderType};

pub trait CollabCloudPluginProvider: Send + Sync + 'static {
  fn provider_type(&self) -> CollabPluginProviderType;

  fn get_plugins(&self, context: CollabPluginProviderContext) -> Vec<Box<dyn CollabPlugin>>;

  fn is_sync_enabled(&self) -> bool;
}

impl<U> CollabCloudPluginProvider for std::sync::Arc<U>
where
  U: CollabCloudPluginProvider,
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
