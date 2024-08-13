use client_api::entity::search_dto::SearchDocumentResponseItem;
use flowy_search_pub::cloud::SearchCloudService;
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;

use anyhow::Error;
use client_api::collab_sync::{SinkConfig, SyncObject, SyncPlugin};
use client_api::entity::ai_dto::{CompletionType, RepeatedRelatedQuestion};
use client_api::entity::ChatMessageType;
use collab::core::origin::{CollabClient, CollabOrigin};

use collab::preclude::CollabPlugin;
use collab_entity::CollabType;
use collab_plugins::cloud_storage::postgres::SupabaseDBPlugin;
use serde_json::Value;
use tokio_stream::wrappers::WatchStream;
use tracing::{debug, info};

use collab_integrate::collab_builder::{
  CollabCloudPluginProvider, CollabPluginProviderContext, CollabPluginProviderType,
};
use flowy_ai_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageMetadata, LocalAIConfig, MessageCursor,
  RepeatedChatMessage, StreamAnswer, StreamComplete,
};
use flowy_database_pub::cloud::{
  CollabDocStateByOid, DatabaseAIService, DatabaseCloudService, DatabaseSnapshot,
  SummaryRowContent, TranslateRowContent, TranslateRowResponse,
};
use flowy_document::deps::DocumentData;
use flowy_document_pub::cloud::{DocumentCloudService, DocumentSnapshot};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_pub::cloud::{
  FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, Workspace, WorkspaceRecord,
};
use flowy_folder_pub::entities::{PublishInfoResponse, PublishPayload};
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_server_pub::supabase_config::SupabaseConfiguration;
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue, StorageCloudService};
use flowy_storage_pub::storage::{CompletedPartRequest, CreateUploadResponse, UploadPartResponse};
use flowy_user_pub::cloud::{UserCloudService, UserCloudServiceProvider};
use flowy_user_pub::entities::{Authenticator, UserTokenState};
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

use crate::integrate::server::{Server, ServerProvider};

#[async_trait]
impl StorageCloudService for ServerProvider {
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

  fn delete_object(&self, url: &str) -> FutureResult<(), FlowyError> {
    let server = self.get_server();
    let url = url.to_string();
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.delete_object(&url).await
    })
  }

  fn get_object(&self, url: String) -> FutureResult<ObjectValue, FlowyError> {
    let server = self.get_server();
    FutureResult::new(async move {
      let storage = server?.file_storage().ok_or(FlowyError::internal())?;
      storage.get_object(url).await
    })
  }

  fn get_object_url_v1(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
  ) -> FlowyResult<String> {
    let server = self.get_server()?;
    let storage = server.file_storage().ok_or(FlowyError::internal())?;
    storage.get_object_url_v1(workspace_id, parent_dir, file_id)
  }

  async fn create_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    file_id: &str,
    content_type: &str,
  ) -> Result<CreateUploadResponse, FlowyError> {
    let server = self.get_server();
    let storage = server?.file_storage().ok_or(FlowyError::internal())?;
    storage
      .create_upload(workspace_id, parent_dir, file_id, content_type)
      .await
  }

  async fn upload_part(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    upload_id: &str,
    file_id: &str,
    part_number: i32,
    body: Vec<u8>,
  ) -> Result<UploadPartResponse, FlowyError> {
    let server = self.get_server();
    let storage = server?.file_storage().ok_or(FlowyError::internal())?;
    storage
      .upload_part(
        workspace_id,
        parent_dir,
        upload_id,
        file_id,
        part_number,
        body,
      )
      .await
  }

  async fn complete_upload(
    &self,
    workspace_id: &str,
    parent_dir: &str,
    upload_id: &str,
    file_id: &str,
    parts: Vec<CompletedPartRequest>,
  ) -> Result<(), FlowyError> {
    let server = self.get_server();
    let storage = server?.file_storage().ok_or(FlowyError::internal())?;
    storage
      .complete_upload(workspace_id, parent_dir, upload_id, file_id, parts)
      .await
  }
}

impl UserCloudServiceProvider for ServerProvider {
  fn set_token(&self, token: &str) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server.set_token(token)?;
    Ok(())
  }

  fn set_ai_model(&self, ai_model: &str) -> Result<(), FlowyError> {
    info!("Set AI model: {}", ai_model);
    let server = self.get_server()?;
    server.set_ai_model(ai_model)?;
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

  fn publish_view(
    &self,
    workspace_id: &str,
    payload: Vec<PublishPayload>,
  ) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .folder_service()
        .publish_view(&workspace_id, payload)
        .await
    })
  }

  fn unpublish_views(&self, workspace_id: &str, view_ids: Vec<String>) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .folder_service()
        .unpublish_views(&workspace_id, view_ids)
        .await
    })
  }

  fn get_publish_info(&self, view_id: &str) -> FutureResult<PublishInfoResponse, Error> {
    let view_id = view_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move { server?.folder_service().get_publish_info(&view_id).await })
  }

  fn set_publish_namespace(
    &self,
    workspace_id: &str,
    new_namespace: &str,
  ) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let new_namespace = new_namespace.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .folder_service()
        .set_publish_namespace(&workspace_id, &new_namespace)
        .await
    })
  }

  fn get_publish_namespace(&self, workspace_id: &str) -> FutureResult<String, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_publish_namespace(&workspace_id)
        .await
    })
  }
}

#[async_trait]
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

#[async_trait]
impl DatabaseAIService for ServerProvider {
  async fn summary_database_row(
    &self,
    workspace_id: &str,
    object_id: &str,
    summary_row: SummaryRowContent,
  ) -> Result<String, FlowyError> {
    self
      .get_server()?
      .database_ai_service()
      .ok_or_else(FlowyError::not_support)?
      .summary_database_row(workspace_id, object_id, summary_row)
      .await
  }

  async fn translate_database_row(
    &self,
    workspace_id: &str,
    translate_row: TranslateRowContent,
    language: &str,
  ) -> Result<TranslateRowResponse, FlowyError> {
    self
      .get_server()?
      .database_ai_service()
      .ok_or_else(FlowyError::not_support)?
      .translate_database_row(workspace_id, translate_row, language)
      .await
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
            Ok(Some((channel, ws_connect_state, _is_connected))) => {
              let origin = CollabOrigin::Client(CollabClient::new(
                collab_object.uid,
                collab_object.device_id.clone(),
              ));
              let sync_object = SyncObject::new(
                &collab_object.object_id,
                &collab_object.workspace_id,
                collab_object.collab_type,
                &collab_object.device_id,
              );
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

#[async_trait]
impl ChatCloudService for ServerProvider {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_server();
    let chat_id = chat_id.to_string();
    let uid = *uid;
    FutureResult::new(async move {
      server?
        .chat_service()
        .create_chat(&uid, &workspace_id, &chat_id)
        .await
    })
  }

  async fn create_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
    metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let message = message.to_string();
    self
      .get_server()?
      .chat_service()
      .create_question(&workspace_id, &chat_id, &message, message_type, metadata)
      .await
  }

  async fn create_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError> {
    let server = self.get_server();
    server?
      .chat_service()
      .create_answer(workspace_id, chat_id, message, question_id, metadata)
      .await
  }

  async fn stream_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let server = self.get_server()?;
    server
      .chat_service()
      .stream_answer(&workspace_id, &chat_id, message_id)
      .await
  }

  async fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_chat_messages(workspace_id, chat_id, offset, limit)
      .await
  }

  async fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_related_message(workspace_id, chat_id, message_id)
      .await
  }

  async fn get_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let server = self.get_server();
    server?
      .chat_service()
      .get_answer(workspace_id, chat_id, question_message_id)
      .await
  }

  async fn stream_complete(
    &self,
    workspace_id: &str,
    text: &str,
    complete_type: CompletionType,
  ) -> Result<StreamComplete, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let text = text.to_string();
    let server = self.get_server()?;
    server
      .chat_service()
      .stream_complete(&workspace_id, &text, complete_type)
      .await
  }

  async fn index_file(
    &self,
    workspace_id: &str,
    file_path: &Path,
    chat_id: &str,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    self
      .get_server()?
      .chat_service()
      .index_file(workspace_id, file_path, chat_id, metadata)
      .await
  }

  async fn get_local_ai_config(&self, workspace_id: &str) -> Result<LocalAIConfig, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_local_ai_config(workspace_id)
      .await
  }
}

#[async_trait]
impl SearchCloudService for ServerProvider {
  async fn document_search(
    &self,
    workspace_id: &str,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError> {
    let server = self.get_server()?;
    match server.search_service() {
      Some(search_service) => search_service.document_search(workspace_id, query).await,
      None => Err(FlowyError::internal().with_context("SearchCloudService not found")),
    }
  }
}
