#![allow(unused_variables)]

use crate::EmbeddingWriter;
use crate::af_cloud::define::LoggedUser;
use crate::local_server::util::default_encode_collab_for_collab_type;
use client_api::entity::PublishInfo;
use client_api::entity::workspace_dto::PublishInfoView;
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_entity::CollabType;
use collab_plugins::local_storage::kv::KVTransactionDB;
use collab_plugins::local_storage::kv::doc::CollabKVAction;
use flowy_error::FlowyError;
use flowy_folder_pub::cloud::{
  FolderCloudService, FolderCollabParams, FolderSnapshot, FullSyncCollabParams,
};
use flowy_folder_pub::entities::PublishPayload;
use flowy_server_pub::guest_dto::{
  RevokeSharedViewAccessRequest, ShareViewWithGuestRequest, SharedViewDetails,
};
use lib_infra::async_trait::async_trait;
use std::sync::Arc;
use uuid::Uuid;

pub(crate) struct LocalServerFolderCloudServiceImpl {
  #[allow(dead_code)]
  pub logged_user: Arc<dyn LoggedUser>,
  pub embedding_writer: Option<Arc<dyn EmbeddingWriter>>,
}

#[async_trait]
impl FolderCloudService for LocalServerFolderCloudServiceImpl {
  async fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> Result<Vec<FolderSnapshot>, FlowyError> {
    Ok(vec![])
  }

  async fn get_folder_doc_state(
    &self,
    workspace_id: &Uuid,
    uid: i64,
    collab_type: CollabType,
    object_id: &Uuid,
  ) -> Result<Vec<u8>, FlowyError> {
    let object_id = object_id.to_string();
    let workspace_id = workspace_id.to_string();
    let collab_db = self.logged_user.get_collab_db(uid)?.upgrade().unwrap();
    let read_txn = collab_db.read_txn();
    let is_exist = read_txn.is_exist(uid, &workspace_id.to_string(), &object_id.to_string());
    if is_exist {
      // load doc
      let collab = Collab::new_with_origin(CollabOrigin::Empty, &object_id, vec![], false);
      read_txn.load_doc(uid, &workspace_id, &object_id, collab.doc())?;
      let data = collab.encode_collab_v1(|c| {
        collab_type
          .validate_require_data(c)
          .map_err(|err| FlowyError::invalid_data().with_context(err))?;
        Ok::<_, FlowyError>(())
      })?;
      Ok(data.doc_state.to_vec())
    } else {
      let data = default_encode_collab_for_collab_type(uid, &object_id, collab_type).await?;
      drop(read_txn);
      Ok(data.doc_state.to_vec())
    }
  }

  async fn full_sync_collab_object(
    &self,
    workspace_id: &Uuid,
    params: FullSyncCollabParams,
  ) -> Result<(), FlowyError> {
    if let Some(embedding_writer) = self.embedding_writer.as_ref() {
      embedding_writer
        .index_encoded_collab(
          *workspace_id,
          params.object_id,
          params.encoded_collab,
          params.collab_type,
        )
        .await?;
    }

    Ok(())
  }

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &Uuid,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  fn service_name(&self) -> String {
    "Local".to_string()
  }

  async fn publish_view(
    &self,
    workspace_id: &Uuid,
    payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn unpublish_views(
    &self,
    workspace_id: &Uuid,
    view_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn get_publish_info(&self, view_id: &Uuid) -> Result<PublishInfo, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn set_publish_name(
    &self,
    workspace_id: &Uuid,
    view_id: Uuid,
    new_name: String,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn set_publish_namespace(
    &self,
    workspace_id: &Uuid,
    new_namespace: String,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn list_published_views(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<PublishInfoView>, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_default_published_view_info(
    &self,
    workspace_id: &Uuid,
  ) -> Result<PublishInfo, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn set_default_published_view(
    &self,
    workspace_id: &Uuid,
    view_id: uuid::Uuid,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn remove_default_published_view(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_publish_namespace(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn import_zip(&self, _file_path: &str) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn share_page_with_user(
    &self,
    workspace_id: &Uuid,
    params: ShareViewWithGuestRequest,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn revoke_shared_page_access(
    &self,
    workspace_id: &Uuid,
    view_id: &Uuid,
    params: RevokeSharedViewAccessRequest,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_shared_page_details(
    &self,
    workspace_id: &Uuid,
    view_id: &Uuid,
  ) -> Result<SharedViewDetails, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }
}
