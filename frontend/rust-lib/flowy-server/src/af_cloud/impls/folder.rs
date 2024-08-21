use anyhow::Error;
use client_api::entity::{
  workspace_dto::CreateWorkspaceParam, CollabParams, PublishCollabItem, PublishCollabMetadata,
  QueryCollab, QueryCollabParams,
};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;
use collab_folder::RepeatedViewIdentifier;
use serde_json::to_vec;
use std::sync::Arc;
use tracing::instrument;
use uuid::Uuid;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_pub::cloud::{
  Folder, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, Workspace,
  WorkspaceRecord,
};
use flowy_folder_pub::entities::{PublishInfoResponse, PublishPayload};
use lib_infra::async_trait::async_trait;

use crate::af_cloud::define::ServerUser;
use crate::af_cloud::impls::util::check_request_workspace_id_is_match;
use crate::af_cloud::AFServer;

pub(crate) struct AFCloudFolderCloudServiceImpl<T> {
  pub inner: T,
  pub user: Arc<dyn ServerUser>,
}

#[async_trait]
impl<T> FolderCloudService for AFCloudFolderCloudServiceImpl<T>
where
  T: AFServer,
{
  async fn create_workspace(&self, _uid: i64, name: &str) -> Result<Workspace, Error> {
    let try_get_client = self.inner.try_get_client();
    let cloned_name = name.to_string();

    let client = try_get_client?;
    let new_workspace = client
      .create_workspace(CreateWorkspaceParam {
        workspace_name: Some(cloned_name),
      })
      .await?;

    Ok(Workspace {
      id: new_workspace.workspace_id.to_string(),
      name: new_workspace.workspace_name,
      created_at: new_workspace.created_at.timestamp(),
      child_views: RepeatedViewIdentifier::new(vec![]),
      created_by: Some(new_workspace.owner_uid),
      last_edited_time: new_workspace.created_at.timestamp(),
      last_edited_by: Some(new_workspace.owner_uid),
    })
  }

  async fn open_workspace(&self, workspace_id: &str) -> Result<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();

    let client = try_get_client?;
    let _ = client.open_workspace(&workspace_id).await?;
    Ok(())
  }

  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, Error> {
    let try_get_client = self.inner.try_get_client();

    let client = try_get_client?;
    let records = client
      .get_user_workspace_info()
      .await?
      .workspaces
      .into_iter()
      .map(|af_workspace| WorkspaceRecord {
        id: af_workspace.workspace_id.to_string(),
        name: af_workspace.workspace_name,
        created_at: af_workspace.created_at.timestamp(),
      })
      .collect::<Vec<_>>();
    Ok(records)
  }

  #[instrument(level = "debug", skip_all)]
  async fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> Result<Option<FolderData>, Error> {
    let uid = *uid;
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    let params = QueryCollabParams {
      workspace_id: workspace_id.clone(),
      inner: QueryCollab::new(workspace_id.clone(), CollabType::Folder),
    };
    let doc_state = try_get_client?
      .get_collab(params)
      .await
      .map_err(FlowyError::from)?
      .encode_collab
      .doc_state
      .to_vec();
    check_request_workspace_id_is_match(&workspace_id, &cloned_user, "get folder data")?;
    let folder = Folder::from_collab_doc_state(
      uid,
      CollabOrigin::Empty,
      DataSource::DocStateV1(doc_state),
      &workspace_id,
      vec![],
    )?;
    Ok(folder.get_folder_data(&workspace_id))
  }

  async fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> Result<Vec<FolderSnapshot>, Error> {
    Ok(vec![])
  }

  #[instrument(level = "debug", skip_all)]
  async fn get_folder_doc_state(
    &self,
    workspace_id: &str,
    _uid: i64,
    collab_type: CollabType,
    object_id: &str,
  ) -> Result<Vec<u8>, Error> {
    let object_id = object_id.to_string();
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    let params = QueryCollabParams {
      workspace_id: workspace_id.clone(),
      inner: QueryCollab::new(object_id, collab_type),
    };
    let doc_state = try_get_client?
      .get_collab(params)
      .await
      .map_err(FlowyError::from)?
      .encode_collab
      .doc_state
      .to_vec();
    check_request_workspace_id_is_match(&workspace_id, &cloned_user, "get folder doc state")?;
    Ok(doc_state)
  }

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &str,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = objects
      .into_iter()
      .map(|object| {
        CollabParams::new(
          object.object_id,
          object.collab_type,
          object.encoded_collab_v1,
        )
      })
      .collect::<Vec<_>>();
    try_get_client?
      .create_collab_list(&workspace_id, params)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  fn service_name(&self) -> String {
    "AppFlowy Cloud".to_string()
  }

  async fn publish_view(
    &self,
    workspace_id: &str,
    payload: Vec<PublishPayload>,
  ) -> Result<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = payload
      .into_iter()
      .filter_map(|object| {
        let (meta, data) = match object {
          PublishPayload::Document(payload) => (payload.meta, payload.data),
          PublishPayload::Database(payload) => {
            (payload.meta, to_vec(&payload.data).unwrap_or_default())
          },
          PublishPayload::Unknown => return None,
        };
        Some(PublishCollabItem {
          meta: PublishCollabMetadata {
            view_id: Uuid::parse_str(&meta.view_id).unwrap_or(Uuid::nil()),
            publish_name: meta.publish_name,
            metadata: meta.metadata,
          },
          data,
        })
      })
      .collect::<Vec<_>>();
    try_get_client?
      .publish_collabs(&workspace_id, params)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn unpublish_views(&self, workspace_id: &str, view_ids: Vec<String>) -> Result<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let view_uuids = view_ids
      .iter()
      .map(|id| Uuid::parse_str(id).unwrap_or(Uuid::nil()))
      .collect::<Vec<_>>();
    try_get_client?
      .unpublish_collabs(&workspace_id, &view_uuids)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn get_publish_info(&self, view_id: &str) -> Result<PublishInfoResponse, Error> {
    let try_get_client = self.inner.try_get_client();
    let view_id = Uuid::parse_str(view_id)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidParams, "Invalid view id"));

    let view_id = view_id?;
    let info = try_get_client?
      .get_published_collab_info(&view_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(PublishInfoResponse {
      view_id: info.view_id.to_string(),
      publish_name: info.publish_name,
      namespace: info.namespace,
    })
  }

  async fn set_publish_namespace(
    &self,
    workspace_id: &str,
    new_namespace: &str,
  ) -> Result<(), Error> {
    let workspace_id = workspace_id.to_string();
    let namespace = new_namespace.to_string();
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .set_workspace_publish_namespace(&workspace_id, &namespace)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn get_publish_namespace(&self, workspace_id: &str) -> Result<String, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let namespace = try_get_client?
      .get_workspace_publish_namespace(&workspace_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(namespace)
  }
}
