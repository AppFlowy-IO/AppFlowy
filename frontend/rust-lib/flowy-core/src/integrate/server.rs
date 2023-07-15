use std::collections::HashMap;
use std::sync::Arc;

use appflowy_integrate::collab_builder::{CollabStorageProvider, CollabStorageType};
use appflowy_integrate::RemoteCollabStorage;
use parking_lot::RwLock;
use serde_repr::*;

use flowy_database2::deps::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_document2::deps::{DocumentCloudService, DocumentData, DocumentSnapshot};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder2::deps::{FolderCloudService, FolderData, FolderSnapshot, Workspace};
use flowy_server::local_server::LocalServer;
use flowy_server::self_host::configuration::self_host_server_configuration;
use flowy_server::self_host::SelfHostServer;
use flowy_server::supabase::SupabaseServer;
use flowy_server::AppFlowyServer;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_sqlite::kv::KV;
use flowy_user::event_map::{UserAuthService, UserCloudServiceProvider};
use flowy_user::services::AuthType;
use lib_infra::future::FutureResult;

use crate::AppFlowyCoreConfig;

const SERVER_PROVIDER_TYPE_KEY: &str = "server_provider_type";

#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ServerProviderType {
  /// Local server provider.
  /// Offline mode, no user authentication and the data is stored locally.
  Local = 0,
  /// Self-hosted server provider.
  /// The [AppFlowy-Server](https://github.com/AppFlowy-IO/AppFlowy-Server) is still a work in
  /// progress.
  SelfHosted = 1,
  /// Supabase server provider.
  /// It uses supabase's postgresql database to store data and user authentication.
  Supabase = 2,
}

/// The [AppFlowyServerProvider] provides list of [AppFlowyServer] base on the [AuthType]. Using
/// the auth type, the [AppFlowyServerProvider] will create a new [AppFlowyServer] if it doesn't
/// exist.
/// Each server implements the [AppFlowyServer] trait, which provides the [UserAuthService], etc.
pub struct AppFlowyServerProvider {
  config: AppFlowyCoreConfig,
  provider_type: RwLock<ServerProviderType>,
  providers: RwLock<HashMap<ServerProviderType, Arc<dyn AppFlowyServer>>>,
  supabase_config: RwLock<Option<SupabaseConfiguration>>,
}

impl AppFlowyServerProvider {
  pub fn new(config: AppFlowyCoreConfig, supabase_config: Option<SupabaseConfiguration>) -> Self {
    Self {
      config,
      provider_type: RwLock::new(current_server_provider()),
      providers: RwLock::new(HashMap::new()),
      supabase_config: RwLock::new(supabase_config),
    }
  }

  pub fn provider_type(&self) -> ServerProviderType {
    self.provider_type.read().clone()
  }

  /// Returns a [AppFlowyServer] trait implementation base on the provider_type.
  fn get_provider(
    &self,
    provider_type: &ServerProviderType,
  ) -> FlowyResult<Arc<dyn AppFlowyServer>> {
    if let Some(provider) = self.providers.read().get(provider_type) {
      return Ok(provider.clone());
    }

    let server = match provider_type {
      ServerProviderType::Local => {
        let server = Arc::new(LocalServer::new(&self.config.storage_path));
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      ServerProviderType::SelfHosted => {
        let config = self_host_server_configuration().map_err(|e| {
          FlowyError::new(
            ErrorCode::InvalidAuthConfig,
            format!(
              "Missing self host config: {:?}. Error: {:?}",
              provider_type, e
            ),
          )
        })?;
        let server = Arc::new(SelfHostServer::new(config));
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      ServerProviderType::Supabase => {
        let config = self.supabase_config.read().clone().ok_or(FlowyError::new(
          ErrorCode::InvalidAuthConfig,
          "Missing supabase config".to_string(),
        ))?;
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(Arc::new(SupabaseServer::new(config)))
      },
    }?;

    self
      .providers
      .write()
      .insert(provider_type.clone(), server.clone());
    Ok(server)
  }
}

impl UserCloudServiceProvider for AppFlowyServerProvider {
  fn update_supabase_config(&self, supabase_config: &SupabaseConfiguration) {
    self
      .supabase_config
      .write()
      .replace(supabase_config.clone());

    supabase_config.write_env();
    if let Ok(provider) = self.get_provider(&self.provider_type.read()) {
      provider.enable_sync(supabase_config.enable_sync);
    }
  }

  /// When user login, the provider type is set by the [AuthType] and save to disk for next use.
  ///
  /// Each [AuthType] has a corresponding [ServerProviderType]. The [ServerProviderType] is used
  /// to create a new [AppFlowyServer] if it doesn't exist. Once the [ServerProviderType] is set,
  /// it will be used when user open the app again.
  ///
  fn set_auth_type(&self, auth_type: AuthType) {
    let provider_type: ServerProviderType = auth_type.into();
    *self.provider_type.write() = provider_type.clone();

    match KV::set_object(SERVER_PROVIDER_TYPE_KEY, provider_type.clone()) {
      Ok(_) => tracing::trace!("Update server provider type to: {:?}", provider_type),
      Err(e) => {
        tracing::error!("🔴Failed to update server provider type: {:?}", e);
      },
    }
  }

  /// Returns the [UserAuthService] base on the current [ServerProviderType].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_auth_service(&self) -> Result<Arc<dyn UserAuthService>, FlowyError> {
    Ok(
      self
        .get_provider(&self.provider_type.read())?
        .user_service(),
    )
  }
}

impl FolderCloudService for AppFlowyServerProvider {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    let name = name.to_string();
    FutureResult::new(async move { server?.folder_service().create_workspace(uid, &name).await })
  }

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_data(&workspace_id)
        .await
    })
  }

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_provider(&self.provider_type.read());
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_latest_snapshot(&workspace_id)
        .await
    })
  }

  fn get_folder_updates(
    &self,
    workspace_id: &str,
    uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_provider(&self.provider_type.read());
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_updates(&workspace_id, uid)
        .await
    })
  }

  fn service_name(&self) -> String {
    self
      .get_provider(&self.provider_type.read())
      .map(|provider| provider.folder_service().service_name())
      .unwrap_or_default()
  }
}

impl DatabaseCloudService for AppFlowyServerProvider {
  fn get_collab_update(&self, object_id: &str) -> FutureResult<CollabObjectUpdate, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_collab_update(&database_id)
        .await
    })
  }

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
  ) -> FutureResult<CollabObjectUpdateByOid, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    FutureResult::new(async move {
      server?
        .database_service()
        .batch_get_collab_updates(object_ids)
        .await
    })
  }

  fn get_collab_latest_snapshot(
    &self,
    object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_collab_latest_snapshot(&database_id)
        .await
    })
  }
}

impl DocumentCloudService for AppFlowyServerProvider {
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_updates(&document_id)
        .await
    })
  }

  fn get_document_latest_snapshot(
    &self,
    document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_latest_snapshot(&document_id)
        .await
    })
  }

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, FlowyError> {
    let server = self.get_provider(&self.provider_type.read());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_data(&document_id)
        .await
    })
  }
}

impl CollabStorageProvider for AppFlowyServerProvider {
  fn storage_type(&self) -> CollabStorageType {
    self.provider_type().into()
  }

  fn get_storage(&self, storage_type: &CollabStorageType) -> Option<Arc<dyn RemoteCollabStorage>> {
    match storage_type {
      CollabStorageType::Local => None,
      CollabStorageType::AWS => None,
      CollabStorageType::Supabase => self
        .get_provider(&ServerProviderType::Supabase)
        .ok()
        .and_then(|provider| provider.collab_storage()),
    }
  }

  fn is_sync_enabled(&self) -> bool {
    self
      .supabase_config
      .read()
      .as_ref()
      .map(|config| config.enable_sync)
      .unwrap_or(false)
  }
}

impl From<AuthType> for ServerProviderType {
  fn from(auth_provider: AuthType) -> Self {
    match auth_provider {
      AuthType::Local => ServerProviderType::Local,
      AuthType::SelfHosted => ServerProviderType::SelfHosted,
      AuthType::Supabase => ServerProviderType::Supabase,
    }
  }
}

impl From<&AuthType> for ServerProviderType {
  fn from(auth_provider: &AuthType) -> Self {
    Self::from(auth_provider.clone())
  }
}

fn current_server_provider() -> ServerProviderType {
  match KV::get_object::<ServerProviderType>(SERVER_PROVIDER_TYPE_KEY) {
    None => ServerProviderType::Local,
    Some(provider_type) => provider_type,
  }
}
