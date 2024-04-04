use flowy_storage::{ObjectIdentity, ObjectStorageService};
use std::sync::Arc;

use anyhow::Error;
use client_api::collab_sync::{SinkConfig, SyncObject, SyncPlugin};

use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::CollabPlugin;
use collab_entity::CollabType;
use collab_plugins::cloud_storage::postgres::SupabaseDBPlugin;
use tokio_stream::wrappers::WatchStream;
use tracing::{debug, instrument};

use collab_integrate::collab_builder::{
  CollabCloudPluginProvider, CollabPluginProviderContext, CollabPluginProviderType,
};
use flowy_database_pub::cloud::{CollabDocStateByOid, DatabaseCloudService, DatabaseSnapshot};
use flowy_document::deps::DocumentData;
use flowy_document_pub::cloud::{DocumentCloudService, DocumentSnapshot};
use flowy_error::FlowyError;
use flowy_folder_pub::cloud::{
  FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, Workspace, WorkspaceRecord,
};
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_server_pub::supabase_config::SupabaseConfiguration;
use flowy_storage::ObjectValue;
use flowy_user_pub::cloud::{UserCloudService, UserCloudServiceProvider};
use flowy_user_pub::entities::{Authenticator, UserTokenState};
use lib_infra::future::FutureResult;

use crate::integrate::server::{Server, ServerProvider};

impl ObjectStorageService for ServerProvider {
  fn get_object_url(&self, object_id: ObjectIdentity) -> FutureResult<String, FlowyError> {
    let server = self.get_server();
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.get_object_url(object_id).await
    })
  }

  fn put_object(&self, url: String, val: ObjectValue) -> FutureResult<(), FlowyError> {
    let server = self.get_server();
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.put_object(url, val).await
    })
  }

  fn delete_object(&self, url: String) -> FutureResult<(), FlowyError> {
    let server = self.get_server();
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.delete_object(url).await
    })
  }

  fn get_object(&self, url: String) -> FutureResult<flowy_storage::ObjectValue, FlowyError> {
    let server = self.get_server();
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.get_object(url).await
    })
  }
}

impl UserCloudServiceProvider for ServerProvider {
  fn set_token(&self, token: &str) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server.set_token(token)?;
    Ok(())
  }

  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    let server = self.get_server().ok()?;
    server.subscribe_token_state()
  }

  fn set_enable_sync(&self, uid: i64, enable_sync: bool) {
    if let Ok(server) = self.get_server() {
      server.set_enable_sync(uid, enable_sync);
      *self.user_enable_sync.write() = enable_sync;
      *self.uid.write() = Some(uid);
    }
  }

  /// When user login, the provider type is set by the [Authenticator] and save to disk for next use.
  ///
  /// Each [Authenticator] has a corresponding [Server]. The [Server] is used
  /// to create a new [AppFlowyServer] if it doesn't exist. Once the [Server] is set,
  /// it will be used when user open the app again.
  ///
  fn set_user_authenticator(&self, authenticator: &Authenticator) {
    self.set_authenticator(authenticator.clone());
  }

  fn get_user_authenticator(&self) -> Authenticator {
    self.get_authenticator()
  }

  fn set_network_reachable(&self, reachable: bool) {
    if let Ok(server) = self.get_server() {
      server.set_network_reachable(reachable);
    }
  }

  fn set_encrypt_secret(&self, secret: String) {
    tracing::info!("🔑Set encrypt secret");
    self.encryption.write().set_secret(secret);
  }

  /// Returns the [UserCloudService] base on the current [Server].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError> {
    let user_service = self.get_server()?.user_service();
    Ok(user_service)
  }

  fn service_url(&self) -> String {
    match self.get_server_type() {
      Server::Local => "".to_string(),
      Server::AppFlowyCloud => AFCloudConfiguration::from_env()
        .map(|config| config.base_url)
        .unwrap_or_default(),
      Server::Supabase => SupabaseConfiguration::from_env()
        .map(|config| config.url)
        .unwrap_or_default(),
    }
  }
}

impl FolderCloudService for ServerProvider {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let server = self.get_server();
    let name = name.to_string();
    FutureResult::new(async move { server?.folder_service().create_workspace(uid, &name).await })
  }

  fn open_workspace(&self, workspace_id: &str) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move { server?.folder_service().open_workspace(&workspace_id).await })
  }

  fn get_all_workspace(&self) -> FutureResult<Vec<WorkspaceRecord>, Error> {
    let server = self.get_server();
    FutureResult::new(async move { server?.folder_service().get_all_workspace().await })
  }

  fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> FutureResult<Option<FolderData>, Error> {
    let uid = *uid;
    let server = self.get_server();
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
    let server = self.get_server();
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
    collab_type: CollabType,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, Error> {
    let object_id = object_id.to_string();
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_doc_state(&workspace_id, uid, collab_type, &object_id)
        .await
    })
  }

  fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &str,
    objects: Vec<FolderCollabParams>,
  ) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .folder_service()
        .batch_create_folder_collab_objects(&workspace_id, objects)
        .await
    })
  }

  fn service_name(&self) -> String {
    self
      .get_server()
      .map(|provider| provider.folder_service().service_name())
      .unwrap_or_default()
  }
}

impl DatabaseCloudService for ServerProvider {
  fn get_database_object_doc_state(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> FutureResult<Option<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_database_object_doc_state(&database_id, collab_type, &workspace_id)
        .await
    })
  }

  fn batch_get_database_object_doc_state(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .database_service()
        .batch_get_database_object_doc_state(object_ids, object_ty, &workspace_id)
        .await
    })
  }

  fn get_database_collab_object_snapshots(
    &self,
    object_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    let server = self.get_server();
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_database_collab_object_snapshots(&database_id, limit)
        .await
    })
  }
}

impl DocumentCloudService for ServerProvider {
  fn get_document_doc_state(
    &self,
    document_id: &str,
    workspace_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let document_id = document_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_doc_state(&document_id, &workspace_id)
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
    let server = self.get_server();
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
    let server = self.get_server();
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_data(&document_id, &workspace_id)
        .await
    })
  }
}

impl CollabCloudPluginProvider for ServerProvider {
  fn provider_type(&self) -> CollabPluginProviderType {
    self.get_server_type().into()
  }

  #[instrument(level = "debug", skip(self, context), fields(server_type = %self.get_server_type()))]
  fn get_plugins(&self, context: CollabPluginProviderContext) -> Vec<Box<dyn CollabPlugin>> {
    // If the user is local, we don't need to create a sync plugin.
    if self.get_server_type().is_local() {
      debug!(
        "User authenticator is local, skip create sync plugin for: {}",
        context
      );
      return vec![];
    }

    match context {
      CollabPluginProviderContext::Local => vec![],
      CollabPluginProviderContext::AppFlowyCloud {
        uid: _,
        collab_object,
        local_collab,
      } => {
        if let Ok(server) = self.get_server() {
          // to_fut(async move {
          let mut plugins: Vec<Box<dyn CollabPlugin>> = vec![];
          // If the user is local, we don't need to create a sync plugin.

          match server.collab_ws_channel(&collab_object.object_id) {
            Ok(Some((channel, ws_connect_state, is_connected))) => {
              let origin = CollabOrigin::Client(CollabClient::new(
                collab_object.uid,
                collab_object.device_id.clone(),
              ));
              let sync_object = SyncObject::from(collab_object);
              let (sink, stream) = (channel.sink(), channel.stream());
              let sink_config = SinkConfig::new().send_timeout(8);
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
              plugins.push(Box::new(sync_plugin));
            },
            Ok(None) => {
              tracing::error!("🔴Failed to get collab ws channel: channel is none");
            },
            Err(err) => tracing::error!("🔴Failed to get collab ws channel: {:?}", err),
          }
          plugins
        } else {
          vec![]
        }
      },
      CollabPluginProviderContext::Supabase {
        uid,
        collab_object,
        local_collab,
        local_collab_db,
      } => {
        let mut plugins: Vec<Box<dyn CollabPlugin>> = vec![];
        if let Some(remote_collab_storage) = self
          .get_server()
          .ok()
          .and_then(|provider| provider.collab_storage(&collab_object))
        {
          plugins.push(Box::new(SupabaseDBPlugin::new(
            uid,
            collab_object,
            local_collab,
            1,
            remote_collab_storage,
            local_collab_db,
          )));
        }
        plugins
      },
    }
  }

  fn is_sync_enabled(&self) -> bool {
    *self.user_enable_sync.read()
  }
}
