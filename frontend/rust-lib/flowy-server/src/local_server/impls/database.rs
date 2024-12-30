use collab::entity::EncodedCollab;
use collab_database::database::default_database_data;
use collab_database::workspace_database::default_workspace_database_data;
use collab_document::document_data::default_document_collab_data;
use collab_entity::CollabType;
use collab_user::core::default_user_awareness_data;
use flowy_database_pub::cloud::{DatabaseCloudService, DatabaseSnapshot, EncodeCollabByOid};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

#[async_trait]
impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  async fn get_database_encode_collab(
    &self,
    object_id: &str,
    collab_type: CollabType,
    _workspace_id: &str,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    match collab_type {
      CollabType::Document => {
        let encode_collab = default_document_collab_data(object_id)?;
        Ok(Some(encode_collab))
      },
      CollabType::Database => default_database_data(object_id)
        .await
        .map(Some)
        .map_err(Into::into),
      CollabType::WorkspaceDatabase => Ok(Some(default_workspace_database_data(object_id))),
      CollabType::Folder => Ok(None),
      CollabType::DatabaseRow => Ok(None),
      CollabType::UserAwareness => Ok(Some(default_user_awareness_data(object_id))),
      CollabType::Unknown => Ok(None),
    }
  }

  async fn create_database_encode_collab(
    &self,
    _object_id: &str,
    _collab_type: CollabType,
    _workspace_id: &str,
    _encoded_collab: EncodedCollab,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn batch_get_database_encode_collab(
    &self,
    _object_ids: Vec<String>,
    _object_ty: CollabType,
    _workspace_id: &str,
  ) -> Result<EncodeCollabByOid, FlowyError> {
    Ok(EncodeCollabByOid::default())
  }

  async fn get_database_collab_object_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> Result<Vec<DatabaseSnapshot>, FlowyError> {
    Ok(vec![])
  }
}
