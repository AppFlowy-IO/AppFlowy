use client_api::ws::ConnectState;
use client_api::ws::WSConnectStateReceiver;
use client_api::ws::WebSocketChannel;
use flowy_search_pub::cloud::SearchCloudService;
use std::sync::Arc;

use anyhow::Error;
use arc_swap::ArcSwapOption;
use client_api::collab_sync::ServerCollabMessage;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use flowy_ai_pub::cloud::ChatCloudService;
use flowy_ai_pub::entities::UnindexedCollab;
use flowy_database_pub::cloud::{DatabaseAIService, DatabaseCloudService};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_error::FlowyResult;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_storage_pub::cloud::StorageCloudService;
use flowy_user_pub::cloud::UserCloudService;
use flowy_user_pub::entities::UserTokenState;
use lib_infra::async_trait::async_trait;
use tokio_stream::wrappers::WatchStream;
use uuid::Uuid;

#[async_trait]
pub trait EmbeddingWriter: Send + Sync + 'static {
  async fn index_encoded_collab(
    &self,
    workspace_id: Uuid,
    object_id: Uuid,
    data: EncodedCollab,
    collab_type: CollabType,
  ) -> FlowyResult<()>;

  async fn index_unindexed_collab(&self, data: UnindexedCollab) -> FlowyResult<()>;
}

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
  fn set_token(&self, _token: &str) -> Result<(), Error>;

  fn set_ai_model(&self, _ai_model: &str) -> Result<(), Error> {
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

  fn database_ai_service(&self) -> Option<Arc<dyn DatabaseAIService>>;

  /// Facilitates cloud-based document management. This service offers operations for updating documents,
  /// fetching snapshots, and accessing primary document data in an asynchronous manner.
  ///
  /// # Returns
  ///
  /// An `Arc` wrapping the `DocumentCloudService` interface.
  fn document_service(&self) -> Arc<dyn DocumentCloudService>;

  fn chat_service(&self) -> Arc<dyn ChatCloudService>;

  /// Bridge for the Cloud AI Search features
  ///
  fn search_service(&self) -> Option<Arc<dyn SearchCloudService>>;

  fn subscribe_ws_state(&self) -> Option<WSConnectStateReceiver> {
    None
  }

  fn get_ws_state(&self) -> ConnectState {
    ConnectState::Lost
  }

  #[allow(clippy::type_complexity)]
  fn collab_ws_channel(
    &self,
    _object_id: &str,
  ) -> Result<
    Option<(
      Arc<WebSocketChannel<ServerCollabMessage>>,
      WSConnectStateReceiver,
      bool,
    )>,
    anyhow::Error,
  > {
    Ok(None)
  }

  fn file_storage(&self) -> Option<Arc<dyn StorageCloudService>>;
}

pub struct EncryptionImpl {
  secret: ArcSwapOption<String>,
}

impl EncryptionImpl {
  pub fn new(secret: Option<String>) -> Self {
    Self {
      secret: ArcSwapOption::from(secret.map(Arc::new)),
    }
  }
}

impl AppFlowyEncryption for EncryptionImpl {
  fn get_secret(&self) -> Option<String> {
    self.secret.load().as_ref().map(|s| s.to_string())
  }

  fn set_secret(&self, secret: String) {
    self.secret.store(Some(secret.into()));
  }
}
