use std::sync::Arc;

use anyhow::Error;
use bytes::Bytes;
use client_api::collab_sync::{SinkConfig, SinkStrategy, SyncObject, SyncPlugin};
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::CollabPlugin;
use collab_entity::CollabType;
use tokio_stream::wrappers::WatchStream;
use tracing::instrument;

use collab_integrate::collab_builder::{
  CollabDataSource, CollabStorageProvider, CollabStorageProviderContext,
};
use collab_integrate::postgres::SupabaseDBPlugin;
use flowy_database_deps::cloud::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_document2::deps::DocumentData;
use flowy_document_deps::cloud::{DocumentCloudService, DocumentSnapshot};
use flowy_error::FlowyError;
use flowy_folder_deps::cloud::{
  FolderCloudService, FolderData, FolderSnapshot, Workspace, WorkspaceRecord,
};
use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_storage::{FileStorageService, StorageObject};
use flowy_user::event_map::UserCloudServiceProvider;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::{Authenticator, UserTokenState};
use lib_infra::future::{to_fut, Fut, FutureResult};

use crate::integrate::server::{ServerProvider, ServerType, SERVER_PROVIDER_TYPE_KEY};

impl FileStorageService for ServerProvider {
  fn create_object(&self, object: StorageObject) -> FutureResult<String, FlowyError> {
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.create_object(object).await
    })
  }

  fn delete_object_by_url(&self, object_url: String) -> FutureResult<(), FlowyError> {
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.delete_object_by_url(object_url).await
    })
  }

  fn get_object_by_url(&self, object_url: String) -> FutureResult<Bytes, FlowyError> {
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.get_object_by_url(object_url).await
    })
  }
}

impl UserCloudServiceProvider for ServerProvider {
  fn set_token(&self, token: &str) -> Result<(), FlowyError> {
    let server = self.get_server(&self.get_server_type())?;
    server.set_token(token)?;
    Ok(())
  }

  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    let server = self.get_server(&self.get_server_type()).ok()?;
    server.subscribe_token_state()
  }

  fn set_enable_sync(&self, uid: i64, enable_sync: bool) {
    if let Ok(server) = self.get_server(&self.get_server_type()) {
      server.set_enable_sync(uid, enable_sync);
      *self.enable_sync.write() = enable_sync;
      *self.uid.write() = Some(uid);
    }
  }

  fn set_network_reachable(&self, reachable: bool) {
    if let Ok(server) = self.get_server(&self.get_server_type()) {
      server.set_network_reachable(reachable);
    }
  }

  fn set_encrypt_secret(&self, secret: String) {
    tracing::info!("🔑Set encrypt secret");
    self.encryption.write().set_secret(secret);
  }

  /// When user login, the provider type is set by the [Authenticator] and save to disk for next use.
  ///
  /// Each [Authenticator] has a corresponding [ServerType]. The [ServerType] is used
  /// to create a new [AppFlowyServer] if it doesn't exist. Once the [ServerType] is set,
  /// it will be used when user open the app again.
  ///
  fn set_authenticator(&self, authenticator: Authenticator) {
    let server_type: ServerType = authenticator.into();
    self.set_server_type(server_type.clone());

    match self.store_preferences.upgrade() {
      None => tracing::error!("🔴Failed to update server provider type: store preferences is drop"),
      Some(store_preferences) => {
        match store_preferences.set_object(SERVER_PROVIDER_TYPE_KEY, server_type.clone()) {
          Ok(_) => tracing::trace!("Set server provider: {:?}", server_type),
          Err(e) => {
            tracing::error!("🔴Failed to update server provider type: {:?}", e);
          },
        }
      },
    }
  }

  fn get_authenticator(&self) -> Authenticator {
    let server_type = self.get_server_type();
    Authenticator::from(server_type)
  }

  /// Returns the [UserCloudService] base on the current [ServerType].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError> {
    let server_type = self.get_server_type();
    let user_service = self.get_server(&server_type)?.user_service();
    Ok(user_service)
  }

  fn service_url(&self) -> String {
    match self.get_server_type() {
      ServerType::Local => "".to_string(),
      ServerType::AFCloud => AFCloudConfiguration::from_env()
        .map(|config| config.base_url)
        .unwrap_or_default(),
      ServerType::Supabase => SupabaseConfiguration::from_env()
        .map(|config| config.url)
        .unwrap_or_default(),
    }
  }
}

impl FolderCloudService for ServerProvider {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let server = self.get_server(&self.get_server_type());
    let name = name.to_string();
    FutureResult::new(async move { server?.folder_service().create_workspace(uid, &name).await })
  }

  fn open_workspace(&self, workspace_id: &str) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move { server?.folder_service().open_workspace(&workspace_id).await })
  }

  fn get_all_workspace(&self) -> FutureResult<Vec<WorkspaceRecord>, Error> {
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move { server?.folder_service().get_all_workspace().await })
  }

  fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> FutureResult<Option<FolderData>, Error> {
    let uid = *uid;
    let server = self.get_server(&self.get_server_type());
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_data(&workspace_id, &uid)
        .await
    })
  }

  fn get_folder_snapshots(
    &self,
    workspace_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<FolderSnapshot>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_snapshots(&workspace_id, limit)
        .await
    })
  }

  fn get_folder_doc_state(
    &self,
    workspace_id: &str,
    uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_doc_state(&workspace_id, uid)
        .await
    })
  }

  fn service_name(&self) -> String {
    self
      .get_server(&self.get_server_type())
      .map(|provider| provider.folder_service().service_name())
      .unwrap_or_default()
  }
}

impl DatabaseCloudService for ServerProvider {
  fn get_collab_update(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabObjectUpdate, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_collab_update(&database_id, collab_type, &workspace_id)
        .await
    })
  }

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabObjectUpdateByOid, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      server?
        .database_service()
        .batch_get_collab_updates(object_ids, object_ty, &workspace_id)
        .await
    })
  }

  fn get_collab_snapshots(
    &self,
    object_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    let server = self.get_server(&self.get_server_type());
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_collab_snapshots(&database_id, limit)
        .await
    })
  }
}

impl DocumentCloudService for ServerProvider {
  fn get_document_updates(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let document_id = document_id.to_string();
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_updates(&document_id, &workspace_id)
        .await
    })
  }

  fn get_document_snapshots(
    &self,
    document_id: &str,
    limit: usize,
    workspace_id: &str,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_snapshots(&document_id, limit, &workspace_id)
        .await
    })
  }

  fn get_document_data(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Option<DocumentData>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_data(&document_id, &workspace_id)
        .await
    })
  }
}

impl CollabStorageProvider for ServerProvider {
  fn storage_source(&self) -> CollabDataSource {
    self.get_server_type().into()
  }

  #[instrument(level = "debug", skip(self, context), fields(server_type = %self.get_server_type()))]
  fn get_plugins(&self, context: CollabStorageProviderContext) -> Fut<Vec<Arc<dyn CollabPlugin>>> {
    match context {
      CollabStorageProviderContext::Local => to_fut(async move { vec![] }),
      CollabStorageProviderContext::AppFlowyCloud {
        uid: _,
        collab_object,
        local_collab,
      } => {
        if let Ok(server) = self.get_server(&ServerType::AFCloud) {
          to_fut(async move {
            let mut plugins: Vec<Arc<dyn CollabPlugin>> = vec![];
            match server.collab_ws_channel(&collab_object.object_id).await {
              Ok(Some((channel, ws_connect_state, is_connected))) => {
                let origin = CollabOrigin::Client(CollabClient::new(
                  collab_object.uid,
                  collab_object.device_id.clone(),
                ));
                let sync_object = SyncObject::from(collab_object);
                let (sink, stream) = (channel.sink(), channel.stream());
                let sink_config = SinkConfig::new()
                  .send_timeout(8)
                  .with_max_payload_size(1024 * 10)
                  .with_strategy(sink_strategy_from_object(&sync_object));
                let sync_plugin = SyncPlugin::new(
                  origin,
                  sync_object,
                  local_collab,
                  sink,
                  sink_config,
                  stream,
                  Some(channel),
                  !is_connected,
                  ws_connect_state,
                );
                plugins.push(Arc::new(sync_plugin));
              },
              Ok(None) => {
                tracing::error!("🔴Failed to get collab ws channel: channel is none");
              },
              Err(err) => tracing::error!("🔴Failed to get collab ws channel: {:?}", err),
            }

            plugins
          })
        } else {
          to_fut(async move { vec![] })
        }
      },
      CollabStorageProviderContext::Supabase {
        uid,
        collab_object,
        local_collab,
        local_collab_db,
      } => {
        let mut plugins: Vec<Arc<dyn CollabPlugin>> = vec![];
        if let Some(remote_collab_storage) = self
          .get_server(&ServerType::Supabase)
          .ok()
          .and_then(|provider| provider.collab_storage(&collab_object))
        {
          plugins.push(Arc::new(SupabaseDBPlugin::new(
            uid,
            collab_object,
            local_collab,
            1,
            remote_collab_storage,
            local_collab_db,
          )));
        }

        to_fut(async move { plugins })
      },
    }
  }

  fn is_sync_enabled(&self) -> bool {
    *self.enable_sync.read()
  }
}

fn sink_strategy_from_object(object: &SyncObject) -> SinkStrategy {
  match object.collab_type {
    CollabType::Document => SinkStrategy::FixInterval(std::time::Duration::from_millis(300)),
    CollabType::Folder => SinkStrategy::ASAP,
    CollabType::Database => SinkStrategy::ASAP,
    CollabType::WorkspaceDatabase => SinkStrategy::ASAP,
    CollabType::DatabaseRow => SinkStrategy::ASAP,
    CollabType::UserAwareness => SinkStrategy::ASAP,
  }
}
