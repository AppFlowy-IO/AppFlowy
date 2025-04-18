use crate::server_layer::ServerProvider;
use client_api::collab_sync::{SinkConfig, SyncObject, SyncPlugin};
use client_api::entity::ai_dto::RepeatedRelatedQuestion;
use client_api::entity::workspace_dto::PublishInfoView;
use client_api::entity::PublishInfo;
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::entity::EncodedCollab;
use collab::preclude::CollabPlugin;
use collab_entity::CollabType;
use collab_integrate::collab_builder::{
  CollabCloudPluginProvider, CollabPluginProviderContext, CollabPluginProviderType,
};
use flowy_ai_pub::cloud::search_dto::{
  SearchDocumentResponseItem, SearchResult, SearchSummaryResult,
};
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, ChatMessageType, ChatSettings, CompleteTextParams,
  MessageCursor, ModelList, RepeatedChatMessage, ResponseFormat, StreamAnswer, StreamComplete,
  UpdateChatParams,
};
use flowy_database_pub::cloud::{
  DatabaseAIService, DatabaseCloudService, DatabaseSnapshot, EncodeCollabByOid, SummaryRowContent,
  TranslateRowContent, TranslateRowResponse,
};
use flowy_document::deps::DocumentData;
use flowy_document_pub::cloud::{DocumentCloudService, DocumentSnapshot};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_pub::cloud::{
  FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, FullSyncCollabParams,
  Workspace, WorkspaceRecord,
};
use flowy_folder_pub::entities::PublishPayload;
use flowy_search_pub::cloud::SearchCloudService;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_storage_pub::cloud::{ObjectIdentity, ObjectValue, StorageCloudService};
use flowy_storage_pub::storage::{CompletedPartRequest, CreateUploadResponse, UploadPartResponse};
use flowy_user_pub::cloud::{UserCloudService, UserCloudServiceProvider};
use flowy_user_pub::entities::{AuthType, UserTokenState};
use lib_infra::async_trait::async_trait;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use std::str::FromStr;
use std::sync::atomic::Ordering;
use std::sync::Arc;
use std::time::Duration;
use tokio_stream::wrappers::WatchStream;
use tracing::log::error;
use tracing::{debug, info};
use uuid::Uuid;

#[async_trait]
impl StorageCloudService for ServerProvider {
  async fn get_object_url(&self, object_id: ObjectIdentity) -> Result<String, FlowyError> {
    let storage = self
      .get_server()?
      .file_storage()
      .ok_or(FlowyError::internal())?;
    storage.get_object_url(object_id).await
  }

  async fn put_object(&self, url: String, val: ObjectValue) -> Result<(), FlowyError> {
    let storage = self
      .get_server()?
      .file_storage()
      .ok_or(FlowyError::internal())?;
    storage.put_object(url, val).await
  }

  async fn delete_object(&self, url: &str) -> Result<(), FlowyError> {
    let storage = self
      .get_server()?
      .file_storage()
      .ok_or(FlowyError::internal())?;
    storage.delete_object(url).await
  }

  async fn get_object(&self, url: String) -> Result<ObjectValue, FlowyError> {
    let storage = self
      .get_server()?
      .file_storage()
      .ok_or(FlowyError::internal())?;
    storage.get_object(url).await
  }

  async fn get_object_url_v1(
    &self,
    workspace_id: &Uuid,
    parent_dir: &str,
    file_id: &str,
  ) -> FlowyResult<String> {
    let server = self.get_server()?;
    let storage = server.file_storage().ok_or(FlowyError::internal())?;
    storage
      .get_object_url_v1(workspace_id, parent_dir, file_id)
      .await
  }

  async fn parse_object_url_v1(&self, url: &str) -> Option<(Uuid, String, String)> {
    self
      .get_server()
      .ok()?
      .file_storage()?
      .parse_object_url_v1(url)
      .await
  }

  async fn create_upload(
    &self,
    workspace_id: &Uuid,
    parent_dir: &str,
    file_id: &str,
    content_type: &str,
    file_size: u64,
  ) -> Result<CreateUploadResponse, FlowyError> {
    let server = self.get_server()?;
    let storage = server.file_storage().ok_or(FlowyError::internal())?;
    storage
      .create_upload(workspace_id, parent_dir, file_id, content_type, file_size)
      .await
  }

  async fn upload_part(
    &self,
    workspace_id: &Uuid,
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
    workspace_id: &Uuid,
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
      self.user_enable_sync.store(enable_sync, Ordering::Release);
      self.uid.store(Some(uid.into()));
    }
  }

  /// When user login, the provider type is set by the [AuthType] and save to disk for next use.
  ///
  /// Each [AuthType] has a corresponding [AuthType]. The [AuthType] is used
  /// to create a new [AppFlowyServer] if it doesn't exist. Once the [AuthType] is set,
  /// it will be used when user open the app again.
  ///
  fn set_server_auth_type(&self, auth_type: &AuthType) {
    self.set_auth_type(*auth_type);
  }

  fn get_server_auth_type(&self) -> AuthType {
    self.get_auth_type()
  }

  fn set_network_reachable(&self, reachable: bool) {
    if let Ok(server) = self.get_server() {
      server.set_network_reachable(reachable);
    }
  }

  fn set_encrypt_secret(&self, secret: String) {
    tracing::info!("🔑Set encrypt secret");
    self.encryption.set_secret(secret);
  }

  /// Returns the [UserCloudService] base on the current [AuthType].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError> {
    let user_service = self.get_server()?.user_service();
    Ok(user_service)
  }

  fn service_url(&self) -> String {
    match self.get_auth_type() {
      AuthType::Local => "".to_string(),
      AuthType::AppFlowyCloud => AFCloudConfiguration::from_env()
        .map(|config| config.base_url)
        .unwrap_or_default(),
    }
  }
}

#[async_trait]
impl FolderCloudService for ServerProvider {
  async fn create_workspace(&self, uid: i64, name: &str) -> Result<Workspace, FlowyError> {
    let server = self.get_server()?;
    let name = name.to_string();
    server.folder_service().create_workspace(uid, &name).await
  }

  async fn open_workspace(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server.folder_service().open_workspace(workspace_id).await
  }

  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, FlowyError> {
    let server = self.get_server()?;
    server.folder_service().get_all_workspace().await
  }

  async fn get_folder_data(
    &self,
    workspace_id: &Uuid,
    uid: &i64,
  ) -> Result<Option<FolderData>, FlowyError> {
    let server = self.get_server()?;

    server
      .folder_service()
      .get_folder_data(workspace_id, uid)
      .await
  }

  async fn get_folder_snapshots(
    &self,
    workspace_id: &str,
    limit: usize,
  ) -> Result<Vec<FolderSnapshot>, FlowyError> {
    let server = self.get_server()?;

    server
      .folder_service()
      .get_folder_snapshots(workspace_id, limit)
      .await
  }

  async fn get_folder_doc_state(
    &self,
    workspace_id: &Uuid,
    uid: i64,
    collab_type: CollabType,
    object_id: &Uuid,
  ) -> Result<Vec<u8>, FlowyError> {
    let server = self.get_server()?;

    server
      .folder_service()
      .get_folder_doc_state(workspace_id, uid, collab_type, object_id)
      .await
  }

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &Uuid,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;

    server
      .folder_service()
      .batch_create_folder_collab_objects(workspace_id, objects)
      .await
  }

  fn service_name(&self) -> String {
    self
      .get_server()
      .map(|provider| provider.folder_service().service_name())
      .unwrap_or_default()
  }

  async fn publish_view(
    &self,
    workspace_id: &Uuid,
    payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;

    server
      .folder_service()
      .publish_view(workspace_id, payload)
      .await
  }

  async fn unpublish_views(
    &self,
    workspace_id: &Uuid,
    view_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .unpublish_views(workspace_id, view_ids)
      .await
  }

  async fn get_publish_info(&self, view_id: &Uuid) -> Result<PublishInfo, FlowyError> {
    let server = self.get_server()?;
    server.folder_service().get_publish_info(view_id).await
  }

  async fn set_publish_name(
    &self,
    workspace_id: &Uuid,
    view_id: Uuid,
    new_name: String,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .set_publish_name(workspace_id, view_id, new_name)
      .await
  }

  async fn set_publish_namespace(
    &self,
    workspace_id: &Uuid,
    new_namespace: String,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .set_publish_namespace(workspace_id, new_namespace)
      .await
  }

  async fn get_publish_namespace(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .get_publish_namespace(workspace_id)
      .await
  }

  /// List all published views of the current workspace.
  async fn list_published_views(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<PublishInfoView>, FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .list_published_views(workspace_id)
      .await
  }

  async fn get_default_published_view_info(
    &self,
    workspace_id: &Uuid,
  ) -> Result<PublishInfo, FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .get_default_published_view_info(workspace_id)
      .await
  }

  async fn set_default_published_view(
    &self,
    workspace_id: &Uuid,
    view_id: uuid::Uuid,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .set_default_published_view(workspace_id, view_id)
      .await
  }

  async fn remove_default_published_view(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server
      .folder_service()
      .remove_default_published_view(workspace_id)
      .await
  }

  async fn import_zip(&self, file_path: &str) -> Result<(), FlowyError> {
    self
      .get_server()?
      .folder_service()
      .import_zip(file_path)
      .await
  }

  async fn full_sync_collab_object(
    &self,
    workspace_id: &Uuid,
    params: FullSyncCollabParams,
  ) -> Result<(), FlowyError> {
    self
      .get_server()?
      .folder_service()
      .full_sync_collab_object(workspace_id, params)
      .await
  }
}

#[async_trait]
impl DatabaseCloudService for ServerProvider {
  async fn get_database_encode_collab(
    &self,
    object_id: &Uuid,
    collab_type: CollabType,
    workspace_id: &Uuid,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    let server = self.get_server()?;
    server
      .database_service()
      .get_database_encode_collab(object_id, collab_type, workspace_id)
      .await
  }

  async fn create_database_encode_collab(
    &self,
    object_id: &Uuid,
    collab_type: CollabType,
    workspace_id: &Uuid,
    encoded_collab: EncodedCollab,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server
      .database_service()
      .create_database_encode_collab(object_id, collab_type, workspace_id, encoded_collab)
      .await
  }

  async fn batch_get_database_encode_collab(
    &self,
    object_ids: Vec<Uuid>,
    object_ty: CollabType,
    workspace_id: &Uuid,
  ) -> Result<EncodeCollabByOid, FlowyError> {
    let server = self.get_server()?;

    server
      .database_service()
      .batch_get_database_encode_collab(object_ids, object_ty, workspace_id)
      .await
  }

  async fn get_database_collab_object_snapshots(
    &self,
    object_id: &Uuid,
    limit: usize,
  ) -> Result<Vec<DatabaseSnapshot>, FlowyError> {
    let server = self.get_server()?;

    server
      .database_service()
      .get_database_collab_object_snapshots(object_id, limit)
      .await
  }
}

#[async_trait]
impl DatabaseAIService for ServerProvider {
  async fn summary_database_row(
    &self,
    _workspace_id: &Uuid,
    _object_id: &Uuid,
    _summary_row: SummaryRowContent,
  ) -> Result<String, FlowyError> {
    self
      .get_server()?
      .database_ai_service()
      .ok_or_else(FlowyError::not_support)?
      .summary_database_row(_workspace_id, _object_id, _summary_row)
      .await
  }

  async fn translate_database_row(
    &self,
    _workspace_id: &Uuid,
    _translate_row: TranslateRowContent,
    _language: &str,
  ) -> Result<TranslateRowResponse, FlowyError> {
    self
      .get_server()?
      .database_ai_service()
      .ok_or_else(FlowyError::not_support)?
      .translate_database_row(_workspace_id, _translate_row, _language)
      .await
  }
}

#[async_trait]
impl DocumentCloudService for ServerProvider {
  async fn get_document_doc_state(
    &self,
    document_id: &Uuid,
    workspace_id: &Uuid,
  ) -> Result<Vec<u8>, FlowyError> {
    let server = self.get_server()?;
    server
      .document_service()
      .get_document_doc_state(document_id, workspace_id)
      .await
  }

  async fn get_document_snapshots(
    &self,
    document_id: &Uuid,
    limit: usize,
    workspace_id: &str,
  ) -> Result<Vec<DocumentSnapshot>, FlowyError> {
    let server = self.get_server()?;

    server
      .document_service()
      .get_document_snapshots(document_id, limit, workspace_id)
      .await
  }

  async fn get_document_data(
    &self,
    document_id: &Uuid,
    workspace_id: &Uuid,
  ) -> Result<Option<DocumentData>, FlowyError> {
    let server = self.get_server()?;
    server
      .document_service()
      .get_document_data(document_id, workspace_id)
      .await
  }

  async fn create_document_collab(
    &self,
    workspace_id: &Uuid,
    document_id: &Uuid,
    encoded_collab: EncodedCollab,
  ) -> Result<(), FlowyError> {
    let server = self.get_server()?;
    server
      .document_service()
      .create_document_collab(workspace_id, document_id, encoded_collab)
      .await
  }
}

impl CollabCloudPluginProvider for ServerProvider {
  fn provider_type(&self) -> CollabPluginProviderType {
    match self.get_auth_type() {
      AuthType::Local => CollabPluginProviderType::Local,
      AuthType::AppFlowyCloud => CollabPluginProviderType::AppFlowyCloud,
    }
  }

  fn get_plugins(&self, context: CollabPluginProviderContext) -> Vec<Box<dyn CollabPlugin>> {
    // If the user is local, we don't need to create a sync plugin.
    if self.get_auth_type().is_local() {
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

              if let (Ok(object_id), Ok(workspace_id)) = (
                Uuid::from_str(&collab_object.object_id),
                Uuid::from_str(&collab_object.workspace_id),
              ) {
                let sync_object = SyncObject::new(
                  object_id,
                  workspace_id,
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
                  Some(Duration::from_secs(60)),
                );
                plugins.push(Box::new(sync_plugin));
              } else {
                error!(
                  "Failed to parse collab object id: {}",
                  collab_object.object_id
                );
              }
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
    }
  }

  fn is_sync_enabled(&self) -> bool {
    self.user_enable_sync.load(Ordering::Acquire)
  }
}

#[async_trait]
impl ChatCloudService for ServerProvider {
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
    name: &str,
    metadata: serde_json::Value,
  ) -> Result<(), FlowyError> {
    let server = self.get_server();
    server?
      .chat_service()
      .create_chat(uid, workspace_id, chat_id, rag_ids, name, metadata)
      .await
  }

  async fn create_question(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<ChatMessage, FlowyError> {
    let message = message.to_string();
    self
      .get_server()?
      .chat_service()
      .create_question(workspace_id, chat_id, &message, message_type)
      .await
  }

  async fn create_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
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
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_id: i64,
    format: ResponseFormat,
    ai_model: Option<AIModel>,
  ) -> Result<StreamAnswer, FlowyError> {
    let server = self.get_server()?;
    server
      .chat_service()
      .stream_answer(workspace_id, chat_id, question_id, format, ai_model)
      .await
  }

  async fn get_chat_messages(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_chat_messages(workspace_id, chat_id, offset, limit)
      .await
  }

  async fn get_question_from_answer_id(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_question_from_answer_id(workspace_id, chat_id, answer_message_id)
      .await
  }

  async fn get_related_message(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    ai_model: Option<AIModel>,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_related_message(workspace_id, chat_id, message_id, ai_model)
      .await
  }

  async fn get_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let server = self.get_server();
    server?
      .chat_service()
      .get_answer(workspace_id, chat_id, question_id)
      .await
  }

  async fn stream_complete(
    &self,
    workspace_id: &Uuid,
    params: CompleteTextParams,
    ai_model: Option<AIModel>,
  ) -> Result<StreamComplete, FlowyError> {
    let server = self.get_server()?;
    server
      .chat_service()
      .stream_complete(workspace_id, params, ai_model)
      .await
  }

  async fn embed_file(
    &self,
    workspace_id: &Uuid,
    file_path: &Path,
    chat_id: &Uuid,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    self
      .get_server()?
      .chat_service()
      .embed_file(workspace_id, file_path, chat_id, metadata)
      .await
  }

  async fn get_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_chat_settings(workspace_id, chat_id)
      .await
  }

  async fn update_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    self
      .get_server()?
      .chat_service()
      .update_chat_settings(workspace_id, chat_id, params)
      .await
  }

  async fn get_available_models(&self, workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_available_models(workspace_id)
      .await
  }

  async fn get_workspace_default_model(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    self
      .get_server()?
      .chat_service()
      .get_workspace_default_model(workspace_id)
      .await
  }
}

#[async_trait]
impl SearchCloudService for ServerProvider {
  async fn document_search(
    &self,
    workspace_id: &Uuid,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError> {
    let server = self.get_server()?;
    match server.search_service() {
      Some(search_service) => search_service.document_search(workspace_id, query).await,
      None => Err(FlowyError::internal().with_context("SearchCloudService not found")),
    }
  }

  async fn generate_search_summary(
    &self,
    workspace_id: &Uuid,
    query: String,
    search_results: Vec<SearchResult>,
  ) -> Result<SearchSummaryResult, FlowyError> {
    let server = self.get_server()?;
    match server.search_service() {
      Some(search_service) => {
        search_service
          .generate_search_summary(workspace_id, query, search_results)
          .await
      },
      None => Err(FlowyError::internal().with_context("SearchCloudService not found")),
    }
  }
}
