use client_api::entity::workspace_dto::{
  CreatePageParams, CreateSpaceParams, DuplicatePageParams, FavoriteFolderView, FavoritePageParams,
  FolderView, MovePageParams, PublishInfoView, RecentFolderView, TrashFolderView, UpdatePageParams,
  UpdateSpaceParams,
};
use client_api::entity::{
  workspace_dto::CreateWorkspaceParam, CollabParams, PublishCollabItem, PublishCollabMetadata,
  QueryCollab, QueryCollabParams,
};
use client_api::entity::{PatchPublishedCollab, PublishInfo};
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;
use collab_folder::RepeatedViewIdentifier;
use serde_json::to_vec;
use std::path::PathBuf;
use std::sync::Arc;
use tracing::{instrument, trace};
use uuid::Uuid;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_pub::cloud::{
  Folder, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, FullSyncCollabParams,
  Workspace, WorkspaceRecord,
};
use flowy_folder_pub::entities::PublishPayload;
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
  async fn create_workspace(&self, _uid: i64, name: &str) -> Result<Workspace, FlowyError> {
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

  async fn open_workspace(&self, workspace_id: &str) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();

    let client = try_get_client?;
    let _ = client.open_workspace(&workspace_id).await?;
    Ok(())
  }

  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, FlowyError> {
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
  ) -> Result<Option<FolderData>, FlowyError> {
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
  ) -> Result<Vec<FolderSnapshot>, FlowyError> {
    Ok(vec![])
  }

  #[instrument(level = "debug", skip_all)]
  async fn get_folder_doc_state(
    &self,
    workspace_id: &str,
    _uid: i64,
    collab_type: CollabType,
    object_id: &str,
  ) -> Result<Vec<u8>, FlowyError> {
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

  async fn full_sync_collab_object(
    &self,
    workspace_id: &str,
    params: FullSyncCollabParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .collab_full_sync(
        &workspace_id,
        &params.object_id,
        params.collab_type,
        params.encoded_collab.doc_state.to_vec(),
        params.encoded_collab.state_vector.to_vec(),
      )
      .await?;
    Ok(())
  }

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &str,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError> {
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
      .await?;
    Ok(())
  }

  fn service_name(&self) -> String {
    "AppFlowy Cloud".to_string()
  }

  async fn publish_view(
    &self,
    workspace_id: &str,
    payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError> {
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
          comments_enabled: true,
          duplicate_enabled: true,
        })
      })
      .collect::<Vec<_>>();
    try_get_client?
      .publish_collabs(&workspace_id, params)
      .await?;
    Ok(())
  }

  async fn unpublish_views(
    &self,
    workspace_id: &str,
    view_ids: Vec<String>,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let view_uuids = view_ids
      .iter()
      .map(|id| Uuid::parse_str(id).unwrap_or(Uuid::nil()))
      .collect::<Vec<_>>();
    try_get_client?
      .unpublish_collabs(&workspace_id, &view_uuids)
      .await?;
    Ok(())
  }

  async fn get_publish_info(&self, view_id: &str) -> Result<PublishInfo, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let view_id = Uuid::parse_str(view_id)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidParams, "Invalid view id"));

    let view_id = view_id?;
    let info = try_get_client?
      .get_published_collab_info(&view_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(info)
  }

  async fn set_publish_name(
    &self,
    workspace_id: &str,
    view_id: String,
    new_name: String,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.inner.try_get_client()?;
    let view_id = Uuid::parse_str(&view_id)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidParams, "Invalid view id"))?;

    try_get_client
      .patch_published_collabs(
        workspace_id,
        &[PatchPublishedCollab {
          view_id,
          publish_name: Some(new_name),
          comments_enabled: Some(true),
          duplicate_enabled: Some(true),
        }],
      )
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn set_publish_namespace(
    &self,
    workspace_id: &str,
    new_namespace: String,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .set_workspace_publish_namespace(&workspace_id, new_namespace)
      .await?;
    Ok(())
  }

  async fn get_publish_namespace(&self, workspace_id: &str) -> Result<String, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let namespace = self
      .inner
      .try_get_client()?
      .get_workspace_publish_namespace(&workspace_id)
      .await?;
    Ok(namespace)
  }

  async fn list_published_views(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<PublishInfoView>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let published_views = self
      .inner
      .try_get_client()?
      .list_published_views(&workspace_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(published_views)
  }

  async fn get_default_published_view_info(
    &self,
    workspace_id: &str,
  ) -> Result<PublishInfo, FlowyError> {
    let default_published_view_info = self
      .inner
      .try_get_client()?
      .get_default_publish_view_info(workspace_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(default_published_view_info)
  }

  async fn set_default_published_view(
    &self,
    workspace_id: &str,
    view_id: uuid::Uuid,
  ) -> Result<(), FlowyError> {
    self
      .inner
      .try_get_client()?
      .set_default_publish_view(workspace_id, view_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn remove_default_published_view(&self, workspace_id: &str) -> Result<(), FlowyError> {
    self
      .inner
      .try_get_client()?
      .delete_default_publish_view(workspace_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn import_zip(&self, file_path: &str) -> Result<(), FlowyError> {
    let file_path = PathBuf::from(file_path);
    let client = self.inner.try_get_client()?;
    let url = client.create_import(&file_path).await?.presigned_url;
    trace!(
      "Importing zip file: {} to url: {}",
      file_path.display(),
      url
    );
    client.upload_import_file(&file_path, &url).await?;
    Ok(())
  }

  async fn get_workspace_folder(
    &self,
    workspace_id: &str,
    depth: Option<u32>,
    root_view_id: Option<String>,
  ) -> Result<FolderView, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    // todo: support depth and root_view_id
    let folder = client
      .get_workspace_folder(&workspace_id, depth, root_view_id)
      .await?;
    Ok(folder)
  }

  async fn create_page(
    &self,
    workspace_id: &str,
    params: CreatePageParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    // change the workspace_id to uuid
    client
      .create_workspace_page_view(Uuid::parse_str(&workspace_id).unwrap(), &params)
      .await?;
    Ok(())
  }

  async fn duplicate_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: DuplicatePageParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .duplicate_view_and_children(Uuid::parse_str(&workspace_id).unwrap(), view_id, &params)
      .await?;
    Ok(())
  }

  async fn move_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: MovePageParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .move_workspace_page_view(Uuid::parse_str(&workspace_id).unwrap(), view_id, &params)
      .await?;
    Ok(())
  }

  async fn move_page_to_trash(&self, workspace_id: &str, view_id: &str) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .move_workspace_page_view_to_trash(Uuid::parse_str(&workspace_id).unwrap(), view_id)
      .await?;
    Ok(())
  }

  async fn restore_page_from_trash(
    &self,
    workspace_id: &str,
    view_id: &str,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .restore_workspace_page_view_from_trash(Uuid::parse_str(&workspace_id).unwrap(), view_id)
      .await?;
    Ok(())
  }

  async fn update_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: UpdatePageParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .update_workspace_page_view(Uuid::parse_str(&workspace_id).unwrap(), view_id, &params)
      .await?;
    Ok(())
  }

  async fn create_space(
    &self,
    workspace_id: &str,
    params: CreateSpaceParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .create_space(Uuid::parse_str(&workspace_id).unwrap(), &params)
      .await?;
    Ok(())
  }

  async fn update_space(
    &self,
    workspace_id: &str,
    space_id: &str,
    params: UpdateSpaceParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .update_space(Uuid::parse_str(&workspace_id).unwrap(), space_id, &params)
      .await?;
    Ok(())
  }

  async fn get_favorite_pages(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<FavoriteFolderView>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    let favorite_pages = client.get_workspace_favorite(&workspace_id).await?;
    Ok(favorite_pages.views)
  }

  async fn update_favorite_page(
    &self,
    workspace_id: &str,
    view_id: &str,
    params: FavoritePageParams,
  ) -> Result<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    client
      .favorite_page_view(Uuid::parse_str(&workspace_id).unwrap(), view_id, &params)
      .await?;
    Ok(())
  }

  async fn get_recent_pages(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<RecentFolderView>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    let recent_pages = client.get_workspace_recent(&workspace_id).await?;
    Ok(recent_pages.views)
  }

  async fn get_trash_pages(&self, workspace_id: &str) -> Result<Vec<TrashFolderView>, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let client = try_get_client?;
    let trash_pages = client.get_workspace_trash(&workspace_id).await?;
    Ok(trash_pages.views)
  }
}
