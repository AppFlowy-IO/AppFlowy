#![allow(unused_variables)]

use crate::af_cloud::define::LoggedUser;
use crate::local_server::util::default_encode_collab_for_collab_type;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use flowy_database_pub::cloud::{DatabaseCloudService, DatabaseSnapshot, EncodeCollabByOid};
use flowy_error::{ErrorCode, FlowyError};
use lib_infra::async_trait::async_trait;
use std::sync::Arc;
use uuid::Uuid;

pub(crate) struct LocalServerDatabaseCloudServiceImpl {
  pub logged_user: Arc<dyn LoggedUser>,
}

#[async_trait]
impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  async fn get_database_encode_collab(
    &self,
    object_id: &Uuid,
    collab_type: CollabType,
    _workspace_id: &Uuid, // underscore to silence “unused” warning
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    let uid = self.logged_user.user_id()?;
    let object_id = object_id.to_string();
    default_encode_collab_for_collab_type(uid, &object_id, collab_type)
      .await
      .map(Some)
      .or_else(|err| {
        if matches!(err.code, ErrorCode::NotSupportYet) {
          Ok(None)
        } else {
          Err(err)
        }
      })
  }

  async fn create_database_encode_collab(
    &self,
    object_id: &Uuid,
    collab_type: CollabType,
    workspace_id: &Uuid,
    encoded_collab: EncodedCollab,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn batch_get_database_encode_collab(
    &self,
    object_ids: Vec<Uuid>,
    object_ty: CollabType,
    workspace_id: &Uuid,
  ) -> Result<EncodeCollabByOid, FlowyError> {
    Ok(EncodeCollabByOid::default())
  }

  async fn get_database_collab_object_snapshots(
    &self,
    object_id: &Uuid,
    limit: usize,
  ) -> Result<Vec<DatabaseSnapshot>, FlowyError> {
    Ok(vec![])
  }
}
