use anyhow::Error;
use collab::preclude::Collab;
use collab_entity::define::{DATABASE, DATABASE_ROW_DATA, WORKSPACE_DATABASES};
use collab_entity::CollabType;
use yrs::{Any, MapPrelim};

use flowy_database_pub::cloud::{
  CollabDocStateByOid, DatabaseCloudService, DatabaseSnapshot, SummaryRowContent,
};
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_database_object_doc_state(
    &self,
    object_id: &str,
    collab_type: CollabType,
    _workspace_id: &str,
  ) -> FutureResult<Option<Vec<u8>>, Error> {
    let object_id = object_id.to_string();
    // create the minimal required data for the given collab type
    FutureResult::new(async move {
      let data = match collab_type {
        CollabType::Database => {
          let collab = Collab::new(1, object_id, collab_type, vec![], false);
          collab.with_origin_transact_mut(|txn| {
            collab.insert_map_with_txn(txn, DATABASE);
          });
          collab
            .encode_collab_v1(|_| Ok::<(), Error>(()))?
            .doc_state
            .to_vec()
        },
        CollabType::WorkspaceDatabase => {
          let collab = Collab::new(1, object_id, collab_type, vec![], false);
          collab.with_origin_transact_mut(|txn| {
            collab.create_array_with_txn::<MapPrelim<Any>>(txn, WORKSPACE_DATABASES, vec![]);
          });
          collab
            .encode_collab_v1(|_| Ok::<(), Error>(()))?
            .doc_state
            .to_vec()
        },
        CollabType::DatabaseRow => {
          let collab = Collab::new(1, object_id, collab_type, vec![], false);
          collab.with_origin_transact_mut(|txn| {
            collab.insert_map_with_txn(txn, DATABASE_ROW_DATA);
          });
          collab
            .encode_collab_v1(|_| Ok::<(), Error>(()))?
            .doc_state
            .to_vec()
        },
        _ => vec![],
      };

      Ok(Some(data))
    })
  }

  fn batch_get_database_object_doc_state(
    &self,
    _object_ids: Vec<String>,
    _object_ty: CollabType,
    _workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error> {
    FutureResult::new(async move { Ok(CollabDocStateByOid::default()) })
  }

  fn get_database_collab_object_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn summary_database_row(
    &self,
    _workspace_id: &str,
    _object_id: &str,
    _summary_row: SummaryRowContent,
  ) -> FutureResult<String, Error> {
    // TODO(lucas): local ai
    FutureResult::new(async move { Ok("".to_string()) })
  }
}
