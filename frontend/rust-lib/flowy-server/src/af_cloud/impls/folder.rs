use anyhow::Error;
use client_api::entity::{
  workspace_dto::CreateWorkspaceParam, CollabParams, QueryCollab, QueryCollabParams,
};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;
use collab_folder::RepeatedViewIdentifier;

use flowy_error::FlowyError;
use flowy_folder_pub::cloud::{
  Folder, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, Workspace,
  WorkspaceRecord,
};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudFolderCloudServiceImpl<T>(pub T);

impl<T> FolderCloudService for AFCloudFolderCloudServiceImpl<T>
where
  T: AFServer,
{
  fn create_workspace(&self, _uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let try_get_client = self.0.try_get_client();
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
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let client = try_get_client?;
      let _ = client.open_workspace(&workspace_id).await?;
      Ok(())
    })
  }

  fn get_all_workspace(&self) -> FutureResult<Vec<WorkspaceRecord>, Error> {
    let try_get_client = self.0.try_get_client();
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

  fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> FutureResult<Option<FolderData>, Error> {
    let uid = *uid;
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        workspace_id: workspace_id.clone(),
        inner: QueryCollab {
          object_id: workspace_id.clone(),
          collab_type: CollabType::Folder,
        },
      };
      let doc_state = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?
        .doc_state
        .to_vec();
      let folder = Folder::from_collab_doc_state(
        uid,
        CollabOrigin::Empty,
        DataSource::DocStateV1(doc_state),
        &workspace_id,
        vec![],
      )?;
      Ok(folder.get_folder_data())
    })
  }

  fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<FolderSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_folder_doc_state(
    &self,
    workspace_id: &str,
    _uid: i64,
    collab_type: CollabType,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, Error> {
    let object_id = object_id.to_string();
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        workspace_id,
        inner: QueryCollab {
          object_id,
          collab_type,
        },
      };
      let doc_state = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?
        .doc_state
        .to_vec();
      Ok(doc_state)
    })
  }

  fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &str,
    objects: Vec<FolderCollabParams>,
  ) -> FutureResult<(), Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = objects
        .into_iter()
        .map(|object| CollabParams {
          object_id: object.object_id,
          encoded_collab_v1: object.encoded_collab_v1,
          collab_type: object.collab_type,
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
}
