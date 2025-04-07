use collab::entity::EncodedCollab;
use collab_database::database::default_database_data;
use collab_database::workspace_database::default_workspace_database_data;
use collab_document::document_data::default_document_collab_data;
use collab_entity::CollabType;
use collab_user::core::default_user_awareness_data;
use flowy_database_pub::cloud::{DatabaseCloudService, DatabaseSnapshot, EncodeCollabByOid};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

#[async_trait]
impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  async fn get_database_encode_collab(
    &self,
    object_id: &Uuid,
    collab_type: CollabType,
    workspace_id: &Uuid,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    let object_id = object_id.to_string();
    match collab_type {
      CollabType::Document => {
        let encode_collab = default_document_collab_data(&object_id)?;
        Ok(Some(encode_collab))
      },
      CollabType::Database => default_database_data(&object_id)
        .await
        .map(Some)
        .map_err(Into::into),
      CollabType::WorkspaceDatabase => Ok(Some(default_workspace_database_data(&object_id))),
      CollabType::Folder => Ok(None),
      CollabType::DatabaseRow => Ok(None),
      CollabType::UserAwareness => Ok(Some(default_user_awareness_data(&object_id))),
      CollabType::Unknown => Ok(None),
    }
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
