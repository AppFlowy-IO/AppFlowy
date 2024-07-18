use anyhow::Error;
use client_api::entity::{
  workspace_dto::CreateWorkspaceParam, CollabParams, PublishCollabItem, PublishCollabMetadata,
  QueryCollab, QueryCollabParams,
};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;
use collab_folder::RepeatedViewIdentifier;
use std::sync::Arc;
use tracing::instrument;
use uuid::Uuid;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_pub::cloud::{
  Folder, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, Workspace,
  WorkspaceRecord,
};
use flowy_folder_pub::entities::{PublishInfoResponse, PublishViewPayload};
use lib_infra::future::FutureResult;

use crate::af_cloud::define::ServerUser;
use crate::af_cloud::impls::util::check_request_workspace_id_is_match;
use crate::af_cloud::AFServer;

pub(crate) struct AFCloudFolderCloudServiceImpl<T> {
  pub inner: T,
  pub user: Arc<dyn ServerUser>,
}

impl<T> FolderCloudService for AFCloudFolderCloudServiceImpl<T>
where
  T: AFServer,
{
  fn create_workspace(&self, _uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let try_get_client = self.inner.try_get_client();
    let cloned_name = name.to_string();
    FutureResult::new(async move {
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
    })
  }

  fn open_workspace(&self, workspace_id: &str) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let _ = client.open_workspace(&workspace_id).await?;
      Ok(())
    })
  }

  fn get_all_workspace(&self) -> FutureResult<Vec<WorkspaceRecord>, Error> {
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
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
    })
  }
  #[instrument(level = "debug", skip_all)]
  fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> FutureResult<Option<FolderData>, Error> {
    let uid = *uid;
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    FutureResult::new(async move {
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
    })
  }

  fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<FolderSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  #[instrument(level = "debug", skip_all)]
  fn get_folder_doc_state(
    &self,
    workspace_id: &str,
    _uid: i64,
    collab_type: CollabType,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, Error> {
    let object_id = object_id.to_string();
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let cloned_user = self.user.clone();
    FutureResult::new(async move {
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
    })
  }

  fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &str,
    objects: Vec<FolderCollabParams>,
  ) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
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
    })
  }

  fn service_name(&self) -> String {
    "AppFlowy Cloud".to_string()
  }

  fn publish_view(
    &self,
    workspace_id: &str,
    payload: Vec<PublishViewPayload>,
  ) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
      let params = payload
        .into_iter()
        .map(|object| PublishCollabItem {
          meta: PublishCollabMetadata {
            view_id: Uuid::parse_str(object.meta.view_id.as_str()).unwrap_or(Uuid::nil()),
            publish_name: object.meta.publish_name,
            metadata: object.meta.metadata,
          },
          data: object.data,
        })
        .collect::<Vec<_>>();
      try_get_client?
        .publish_collabs(&workspace_id, params)
        .await
        .map_err(FlowyError::from)?;
      Ok(())
    })
  }

  fn unpublish_views(&self, workspace_id: &str, view_ids: Vec<String>) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let view_uuids = view_ids
      .iter()
      .map(|id| Uuid::parse_str(id).unwrap_or(Uuid::nil()))
      .collect::<Vec<_>>();
    FutureResult::new(async move {
      try_get_client?
        .unpublish_collabs(&workspace_id, &view_uuids)
        .await
        .map_err(FlowyError::from)?;
      Ok(())
    })
  }

  fn get_publish_info(&self, view_id: &str) -> FutureResult<PublishInfoResponse, Error> {
    let try_get_client = self.inner.try_get_client();
    let view_id = Uuid::parse_str(view_id)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidParams, "Invalid view id"));

    FutureResult::new(async move {
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
    })
  }

  fn set_publish_namespace(
    &self,
    workspace_id: &str,
    new_namespace: &str,
  ) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let namespace = new_namespace.to_string();
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
      try_get_client?
        .set_workspace_publish_namespace(&workspace_id, &namespace)
        .await
        .map_err(FlowyError::from)?;
      Ok(())
    })
  }

  fn get_publish_namespace(&self, workspace_id: &str) -> FutureResult<String, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    FutureResult::new(async move {
      let namespace = try_get_client?
        .get_workspace_publish_namespace(&workspace_id)
        .await
        .map_err(FlowyError::from)?;
      Ok(namespace)
    })
  }
}
