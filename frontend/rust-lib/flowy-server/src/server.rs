use std::sync::Arc;

use anyhow::Error;
use client_api::collab_sync::collab_msg::CollabMessage;
use client_api::ws::{WSConnectStateReceiver, WebSocketChannel};
use collab_entity::CollabObject;
use collab_plugins::cloud_storage::RemoteCollabStorage;
use parking_lot::RwLock;
use tokio_stream::wrappers::WatchStream;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_storage::FileStorageService;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::UserTokenState;
use lib_infra::future::FutureResult;

pub trait AppFlowyEncryption: Send + Sync + 'static {
  fn get_secret(&self) -> Option<String>;
  fn set_secret(&self, secret: String);
}

impl<T> AppFlowyEncryption for Arc<T>
where
  T: AppFlowyEncryption,
{
  fn get_secret(&self) -> Option<String> {
    (**self).get_secret()
  }

  fn set_secret(&self, secret: String) {
    (**self).set_secret(secret)
  }
}

/// `AppFlowyServer` trait defines a collection of services that offer cloud-based interactions
/// and functionalities in AppFlowy. The methods provided ensure efficient, asynchronous operations
/// for managing and accessing user data, folders, collaborative objects, and documents in a cloud environment.
pub trait AppFlowyServer: Send + Sync + 'static {
  fn set_token(&self, _token: &str) -> Result<(), Error> {
    Ok(())
  }

  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    None
  }
  /// Enables or disables server sync.
  ///
  /// # Arguments
  ///
  /// * `_enable` - A boolean to toggle the server synchronization.
  fn set_enable_sync(&self, _uid: i64, _enable: bool) {}

  /// Sets the network reachability status.
  ///
  /// # Arguments
  /// * `reachable`: A boolean indicating whether the network is reachable.
  fn set_network_reachable(&self, _reachable: bool) {}

  /// Provides access to cloud-based user management functionalities. This includes operations
  /// such as user registration, authentication, profile management, and handling of user workspaces.
  /// The interface also offers methods for managing collaborative objects, subscribing to user updates,
  /// and receiving real-time events.
  ///
  /// # Returns
  ///
  /// An `Arc` wrapping the `UserCloudService` interface.
  fn user_service(&self) -> Arc<dyn UserCloudService>;

  /// Provides a service for managing workspaces and folders in a cloud environment. This includes
  /// functionalities to create workspaces, and fetch data, snapshots, and updates related to specific folders.
  ///
  /// # Returns
  ///
  /// An `Arc` wrapping the `FolderCloudService` interface.
  fn folder_service(&self) -> Arc<dyn FolderCloudService>;

  /// Offers a set of operations for interacting with collaborative objects within a cloud database.
  /// This includes functionalities such as retrieval of updates for specific objects, batch fetching,
  /// and obtaining snapshots.
  ///
  /// # Returns
  ///
  /// An `Arc` wrapping the `DatabaseCloudService` interface.
  fn database_service(&self) -> Arc<dyn DatabaseCloudService>;

  /// Facilitates cloud-based document management. This service offers operations for updating documents,
  /// fetching snapshots, and accessing primary document data in an asynchronous manner.
  ///
  /// # Returns
  ///
  /// An `Arc` wrapping the `DocumentCloudService` interface.
  fn document_service(&self) -> Arc<dyn DocumentCloudService>;

  /// Manages collaborative objects within a remote storage system. This includes operations such as
  /// checking storage status, retrieving updates and snapshots, and dispatching updates. The service
  /// also provides subscription capabilities for real-time updates.
  ///
  /// # Arguments
  ///
  /// * `collab_object` - A reference to the collaborative object.
  ///
  /// # Returns
  ///
  /// An `Option` that might contain an `Arc` wrapping the `RemoteCollabStorage` interface.
  fn collab_storage(&self, _collab_object: &CollabObject) -> Option<Arc<dyn RemoteCollabStorage>> {
    None
  }

  #[allow(clippy::type_complexity)]
  fn collab_ws_channel(
    &self,
    _object_id: &str,
  ) -> FutureResult<
    Option<(
      Arc<WebSocketChannel<CollabMessage>>,
      WSConnectStateReceiver,
      bool,
    )>,
    anyhow::Error,
  > {
    FutureResult::new(async { Ok(None) })
  }

  fn file_storage(&self) -> Option<Arc<dyn FileStorageService>>;
}

pub struct EncryptionImpl {
  secret: RwLock<Option<String>>,
}

impl EncryptionImpl {
  pub fn new(secret: Option<String>) -> Self {
    Self {
      secret: RwLock::new(secret),
    }
  }
}

impl AppFlowyEncryption for EncryptionImpl {
  fn get_secret(&self) -> Option<String> {
    self.secret.read().clone()
  }

  fn set_secret(&self, secret: String) {
    *self.secret.write() = Some(secret);
  }
}
