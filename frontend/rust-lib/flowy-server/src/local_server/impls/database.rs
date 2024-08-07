use anyhow::Error;
use collab::core::transaction::DocTransactionExtension;
use collab::preclude::Collab;
use collab_entity::define::{DATABASE, DATABASE_ROW_DATA, WORKSPACE_DATABASES};
use collab_entity::CollabType;
use yrs::{ArrayPrelim, Map, MapPrelim};

use flowy_database_pub::cloud::{CollabDocStateByOid, DatabaseCloudService, DatabaseSnapshot};

use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

#[async_trait]
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
      let mut collab = Collab::new(1, object_id, collab_type.clone(), vec![], false);
      let mut txn = collab.context.transact_mut();
      match collab_type {
        CollabType::Database => {
          collab.data.insert(&mut txn, DATABASE, MapPrelim::default());
        },
        CollabType::WorkspaceDatabase => {
          collab
            .data
            .insert(&mut txn, WORKSPACE_DATABASES, ArrayPrelim::default());
        },
        CollabType::DatabaseRow => {
          collab
            .data
            .insert(&mut txn, DATABASE_ROW_DATA, MapPrelim::default());
        },
        _ => { /* do nothing */ },
      };

      Ok(Some(txn.get_encoded_collab_v1().doc_state.to_vec()))
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
}
