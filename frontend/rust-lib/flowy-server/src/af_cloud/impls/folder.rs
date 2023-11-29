use anyhow::{anyhow, Error};
use client_api::entity::QueryCollabParams;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;

use flowy_error::FlowyError;
use flowy_folder_deps::cloud::{
  Folder, FolderCloudService, FolderData, FolderSnapshot, Workspace, WorkspaceRecord,
};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudFolderCloudServiceImpl<T>(pub T);

impl<T> FolderCloudService for AFCloudFolderCloudServiceImpl<T>
where
  T: AFServer,
{
  fn create_workspace(&self, _uid: i64, _name: &str) -> FutureResult<Workspace, Error> {
    FutureResult::new(async move { Err(anyhow!("Not support yet")) })
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
        object_id: workspace_id.clone(),
        workspace_id: workspace_id.clone(),
        collab_type: CollabType::Folder,
      };
      let doc_state = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?
        .doc_state
        .to_vec();
      let folder = Folder::from_collab_raw_data(
        uid,
        CollabOrigin::Empty,
        vec![doc_state],
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
  ) -> FutureResult<Vec<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        object_id: workspace_id.clone(),
        workspace_id,
        collab_type: CollabType::Folder,
      };
      let doc_state = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?
        .doc_state
        .to_vec();
      Ok(vec![doc_state])
    })
  }

  fn service_name(&self) -> String {
    "AppFlowy Cloud".to_string()
  }
}
