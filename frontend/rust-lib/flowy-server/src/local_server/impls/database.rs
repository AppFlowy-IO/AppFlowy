use anyhow::Error;
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
use flowy_database_pub::cloud::{DatabaseCloudService, DatabaseSnapshot, EncodeCollabByOid};
use lib_infra::async_trait::async_trait;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

#[async_trait]
impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  async fn get_database_encode_collab(
    &self,
    _object_id: &str,
    _collab_type: CollabType,
    _workspace_id: &str,
  ) -> Result<Option<EncodedCollab>, Error> {
    Ok(None)
  }

  async fn batch_get_database_encode_collab(
    &self,
    _object_ids: Vec<String>,
    _object_ty: CollabType,
    _workspace_id: &str,
  ) -> Result<EncodeCollabByOid, Error> {
    Ok(EncodeCollabByOid::default())
  }

  async fn get_database_collab_object_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> Result<Vec<DatabaseSnapshot>, Error> {
    Ok(vec![])
  }
}
