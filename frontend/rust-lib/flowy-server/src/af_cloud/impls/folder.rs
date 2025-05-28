use client_api::entity::workspace_dto::PublishInfoView;
use client_api::entity::{
  CollabParams, PublishCollabItem, PublishCollabMetadata, QueryCollab, QueryCollabParams,
};
use client_api::entity::{PatchPublishedCollab, PublishInfo};
use collab_entity::CollabType;
use flowy_server_pub::guest_dto::{
  ListSharedViewResponse, RevokeSharedViewAccessRequest, ShareViewWithGuestRequest,
  SharedViewDetails,
};
use serde_json::to_vec;
use std::path::PathBuf;
use std::sync::Weak;
use tracing::{instrument, trace};
use uuid::Uuid;

use flowy_error::FlowyError;
use flowy_folder_pub::cloud::{
  FolderCloudService, FolderCollabParams, FolderSnapshot, FullSyncCollabParams,
};
use flowy_folder_pub::entities::PublishPayload;
use lib_infra::async_trait::async_trait;

use crate::af_cloud::AFServer;
use crate::af_cloud::define::LoggedUser;
use crate::af_cloud::impls::util::check_request_workspace_id_is_match;

pub(crate) struct AFCloudFolderCloudServiceImpl<T> {
  pub inner: T,
  pub logged_user: Weak<dyn LoggedUser>,
}

#[async_trait]
impl<T> FolderCloudService for AFCloudFolderCloudServiceImpl<T>
where
  T: AFServer,
{
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
    workspace_id: &Uuid,
    _uid: i64,
    collab_type: CollabType,
    object_id: &Uuid,
  ) -> Result<Vec<u8>, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let params = QueryCollabParams {
      workspace_id: *workspace_id,
      inner: QueryCollab::new(*object_id, collab_type),
    };
    let doc_state = try_get_client?
      .get_collab(params)
      .await
      .map_err(FlowyError::from)?
      .encode_collab
      .doc_state
      .to_vec();
    check_request_workspace_id_is_match(workspace_id, &self.logged_user, "get folder doc state")?;
    Ok(doc_state)
  }

  async fn full_sync_collab_object(
    &self,
    workspace_id: &Uuid,
    params: FullSyncCollabParams,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .collab_full_sync(
        workspace_id,
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
    workspace_id: &Uuid,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError> {
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
      .create_collab_list(workspace_id, params)
      .await?;
    Ok(())
  }

  fn service_name(&self) -> String {
    "AppFlowy Cloud".to_string()
  }

  async fn publish_view(
    &self,
    workspace_id: &Uuid,
    payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError> {
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
      .publish_collabs(workspace_id, params)
      .await?;
    Ok(())
  }

  async fn unpublish_views(
    &self,
    workspace_id: &Uuid,
    view_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .unpublish_collabs(workspace_id, &view_ids)
      .await?;
    Ok(())
  }

  async fn get_publish_info(&self, view_id: &Uuid) -> Result<PublishInfo, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let info = try_get_client?
      .get_published_collab_info(view_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(info)
  }

  async fn set_publish_name(
    &self,
    workspace_id: &Uuid,
    view_id: Uuid,
    new_name: String,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.inner.try_get_client()?;
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
    workspace_id: &Uuid,
    new_namespace: String,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .set_workspace_publish_namespace(workspace_id, new_namespace)
      .await?;
    Ok(())
  }

  async fn list_published_views(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<PublishInfoView>, FlowyError> {
    let published_views = self
      .inner
      .try_get_client()?
      .list_published_views(workspace_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(published_views)
  }

  async fn get_default_published_view_info(
    &self,
    workspace_id: &Uuid,
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
    workspace_id: &Uuid,
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

  async fn remove_default_published_view(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    self
      .inner
      .try_get_client()?
      .delete_default_publish_view(workspace_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn get_publish_namespace(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    let namespace = self
      .inner
      .try_get_client()?
      .get_workspace_publish_namespace(workspace_id)
      .await?;
    Ok(namespace)
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

  async fn share_page_with_user(
    &self,
    workspace_id: &Uuid,
    params: ShareViewWithGuestRequest,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .share_view_with_guest(workspace_id, &params)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn revoke_shared_page_access(
    &self,
    workspace_id: &Uuid,
    view_id: &Uuid,
    params: RevokeSharedViewAccessRequest,
  ) -> Result<(), FlowyError> {
    let try_get_client = self.inner.try_get_client();
    try_get_client?
      .revoke_shared_view_access(workspace_id, view_id, &params)
      .await
      .map_err(FlowyError::from)?;
    Ok(())
  }

  async fn get_shared_page_details(
    &self,
    workspace_id: &Uuid,
    view_id: &Uuid,
  ) -> Result<SharedViewDetails, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let details = try_get_client?
      .get_shared_view_details(workspace_id, view_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(details)
  }

  async fn get_shared_views(
    &self,
    workspace_id: &Uuid,
  ) -> Result<ListSharedViewResponse, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let resp = try_get_client?
      .get_shared_views(workspace_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(resp)
  }
}
