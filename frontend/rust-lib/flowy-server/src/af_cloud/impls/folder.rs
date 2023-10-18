use anyhow::Error;
use client_api::entity::QueryCollabParams;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;

use flowy_error::FlowyError;
use flowy_folder_deps::cloud::{Folder, FolderCloudService, FolderData, FolderSnapshot, Workspace};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudFolderCloudServiceImpl<T>(pub T);

impl<T> FolderCloudService for AFCloudFolderCloudServiceImpl<T>
where
  T: AFServer,
{
  fn create_workspace(&self, _uid: i64, _name: &str) -> FutureResult<Workspace, Error> {
    FutureResult::new(async move { todo!() })
  }

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        object_id: workspace_id.clone(),
        collab_type: CollabType::Folder,
      };
      let updates = vec![try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?];
      let folder =
        Folder::from_collab_raw_data(CollabOrigin::Empty, updates, &workspace_id, vec![])?;
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

  fn get_folder_updates(&self, workspace_id: &str, _uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.0.try_get_client();
    FutureResult::new(async move {
      let params = QueryCollabParams {
        object_id: workspace_id,
        collab_type: CollabType::Folder,
      };
      let update = try_get_client?
        .get_collab(params)
        .await
        .map_err(FlowyError::from)?;
      Ok(vec![update])
    })
  }

  fn service_name(&self) -> String {
    "AppFlowy Cloud".to_string()
  }
}
