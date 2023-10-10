use std::sync::Arc;
use std::time::Duration;

use anyhow::Error;
use bytes::Bytes;
use client_api::collab_sync::{SinkConfig, SinkStrategy, SyncObject, SyncPlugin};
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::CollabPlugin;
use collab_entity::CollabType;
use tokio_stream::wrappers::WatchStream;

use collab_integrate::collab_builder::{CollabPluginContext, CollabSource, CollabStorageProvider};
use collab_integrate::postgres::SupabaseDBPlugin;
use flowy_database_deps::cloud::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_document2::deps::DocumentData;
use flowy_document_deps::cloud::{DocumentCloudService, DocumentSnapshot};
use flowy_error::FlowyError;
use flowy_folder_deps::cloud::{FolderCloudService, FolderData, FolderSnapshot, Workspace};
use flowy_storage::{FileStorageService, StorageObject};
use flowy_user::event_map::UserCloudServiceProvider;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::{AuthType, UserTokenState};
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
    match self.get_server(&self.get_server_type()) {
      Ok(server) => {
        server.set_enable_sync(uid, enable_sync);
        *self.enable_sync.write() = enable_sync;
        *self.uid.write() = Some(uid);
      },
      Err(e) => tracing::error!("🔴Failed to enable sync: {:?}", e),
    }
  }

  fn set_encrypt_secret(&self, secret: String) {
    tracing::info!("🔑Set encrypt secret");
    self.encryption.write().set_secret(secret);
  }

  /// When user login, the provider type is set by the [AuthType] and save to disk for next use.
  ///
  /// Each [AuthType] has a corresponding [ServerType]. The [ServerType] is used
  /// to create a new [AppFlowyServer] if it doesn't exist. Once the [ServerType] is set,
  /// it will be used when user open the app again.
  ///
  fn set_auth_type(&self, auth_type: AuthType) {
    let server_type: ServerType = auth_type.into();
    self.set_server_type(server_type.clone());

    match self.store_preferences.upgrade() {
      None => tracing::error!("🔴Failed to update server provider type: store preferences is drop"),
      Some(store_preferences) => {
        match store_preferences.set_object(SERVER_PROVIDER_TYPE_KEY, server_type.clone()) {
          Ok(_) => tracing::trace!("Update server provider type to: {:?}", server_type),
          Err(e) => {
            tracing::error!("🔴Failed to update server provider type: {:?}", e);
          },
        }
      },
    }
  }

  fn set_device_id(&self, device_id: &str) {
    if device_id.is_empty() {
      tracing::error!("🔴Device id is empty");
      return;
    }

    *self.device_id.write() = device_id.to_string();
  }

  /// Returns the [UserCloudService] base on the current [ServerType].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError> {
    if let Some(user_service) = self.cache_user_service.read().get(&self.get_server_type()) {
      return Ok(user_service.clone());
    }

    let server_type = self.get_server_type();
    let user_service = self.get_server(&server_type)?.user_service();
    self
      .cache_user_service
      .write()
      .insert(server_type, user_service.clone());
    Ok(user_service)
  }

  fn service_name(&self) -> String {
    self.get_server_type().to_string()
  }
}

impl FolderCloudService for ServerProvider {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let server = self.get_server(&self.get_server_type());
    let name = name.to_string();
    FutureResult::new(async move { server?.folder_service().create_workspace(uid, &name).await })
  }

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, Error> {
    let server = self.get_server(&self.get_server_type());
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_data(&workspace_id)
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

  fn get_folder_updates(&self, workspace_id: &str, uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_updates(&workspace_id, uid)
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
  ) -> FutureResult<CollabObjectUpdate, Error> {
    let server = self.get_server(&self.get_server_type());
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_collab_update(&database_id, collab_type)
        .await
    })
  }

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, Error> {
    let server = self.get_server(&self.get_server_type());
    FutureResult::new(async move {
      server?
        .database_service()
        .batch_get_collab_updates(object_ids, object_ty)
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
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, Error> {
    let server = self.get_server(&self.get_server_type());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_updates(&document_id)
        .await
    })
  }

  fn get_document_snapshots(
    &self,
    document_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<DocumentSnapshot>, Error> {
    let server = self.get_server(&self.get_server_type());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_snapshots(&document_id, limit)
        .await
    })
  }

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, Error> {
    let server = self.get_server(&self.get_server_type());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_data(&document_id)
        .await
    })
  }
}

impl CollabStorageProvider for ServerProvider {
  fn storage_source(&self) -> CollabSource {
    self.get_server_type().into()
  }

  fn get_plugins(&self, context: CollabPluginContext) -> Fut<Vec<Arc<dyn CollabPlugin>>> {
    match context {
      CollabPluginContext::Local => to_fut(async move { vec![] }),
      CollabPluginContext::AppFlowyCloud {
        uid: _,
        collab_object,
        local_collab,
      } => {
        if let Ok(server) = self.get_server(&ServerType::AFCloud) {
          to_fut(async move {
            let mut plugins: Vec<Arc<dyn CollabPlugin>> = vec![];
            match server.collab_ws_channel(&collab_object.object_id).await {
              Ok(Some((channel, ws_connect_state))) => {
                let origin = CollabOrigin::Client(CollabClient::new(
                  collab_object.uid,
                  collab_object.device_id.clone(),
                ));
                let sync_object = SyncObject::from(collab_object);
                let (sink, stream) = (channel.sink(), channel.stream());
                let sink_config = SinkConfig::new()
                  .send_timeout(6)
                  .with_strategy(SinkStrategy::FixInterval(Duration::from_secs(2)));
                let sync_plugin = SyncPlugin::new(
                  origin,
                  sync_object,
                  local_collab,
                  sink,
                  sink_config,
                  stream,
                  Some(channel),
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
      CollabPluginContext::Supabase {
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
