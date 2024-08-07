use std::future::Future;
use std::ops::Deref;
use std::pin::Pin;
use std::sync::Arc;

use anyhow::{anyhow, Error};
use collab::preclude::{Collab, ReadTxn, StateVector};
use collab_database::database::get_database_row_ids;
use collab_database::rows::database_row_document_id_from_row_id;
use collab_database::workspace_database::{DatabaseMeta, DatabaseMetaList};
use collab_entity::{CollabObject, CollabType};
use collab_folder::{Folder, View, ViewLayout};
use collab_plugins::local_storage::kv::KVTransactionDB;
use parking_lot::Mutex;

use collab_integrate::{CollabKVAction, CollabKVDB, PersistenceError};
use flowy_error::FlowyResult;
use flowy_user_pub::cloud::UserCloudService;
use flowy_user_pub::session::Session;

#[tracing::instrument(level = "info", skip_all, err)]
pub async fn sync_supabase_user_data_to_cloud(
  user_service: Arc<dyn UserCloudService>,
  device_id: &str,
  new_user_session: &Session,
  collab_db: &Arc<CollabKVDB>,
) -> FlowyResult<()> {
  let workspace_id = new_user_session.user_workspace.id.clone();
  let uid = new_user_session.user_id;
  let folder = Arc::new(
    sync_folder(
      uid,
      &workspace_id,
      device_id,
      collab_db,
      user_service.clone(),
    )
    .await?,
  );

  let database_records = sync_database_views(
    uid,
    &workspace_id,
    device_id,
    &new_user_session.user_workspace.database_indexer_id,
    collab_db,
    user_service.clone(),
  )
  .await;

  let views = folder.lock().get_views_belong_to(&workspace_id);
  for view in views {
    let view_id = view.id.clone();
    if let Err(err) = sync_view(
      uid,
      folder.clone(),
      database_records.clone(),
      workspace_id.to_string(),
      device_id.to_string(),
      view,
      collab_db.clone(),
      user_service.clone(),
    )
    .await
    {
      tracing::error!("🔴sync {} failed: {:?}", view_id, err);
    }
  }
  tokio::task::yield_now().await;
  Ok(())
}

#[allow(clippy::too_many_arguments)]
fn sync_view(
  uid: i64,
  folder: Arc<MutexFolder>,
  database_metas: Vec<Arc<DatabaseMeta>>,
  workspace_id: String,
  device_id: String,
  view: Arc<View>,
  collab_db: Arc<CollabKVDB>,
  user_service: Arc<dyn UserCloudService>,
) -> Pin<Box<dyn Future<Output = Result<(), Error>> + Send + Sync>> {
  Box::pin(async move {
    let collab_type = collab_type_from_view_layout(&view.layout);
    let object_id = object_id_from_view(&view, &database_metas)?;
    tracing::debug!(
      "sync view: {:?}:{} with object_id: {}",
      view.layout,
      view.id,
      object_id
    );

    let collab_object = CollabObject::new(
      uid,
      object_id,
      collab_type,
      workspace_id.to_string(),
      device_id.clone(),
    );

    match view.layout {
      ViewLayout::Document => {
        let doc_state = get_collab_doc_state(uid, &collab_object, &collab_db)?;
        tracing::info!(
          "sync object: {} with update: {}",
          collab_object,
          doc_state.len()
        );
        user_service
          .create_collab_object(&collab_object, doc_state)
          .await?;
      },
      ViewLayout::Grid | ViewLayout::Board | ViewLayout::Calendar => {
        let (database_doc_state, row_ids) =
          get_database_doc_state(uid, &collab_object, &collab_db)?;
        tracing::info!(
          "sync object: {} with update: {}",
          collab_object,
          database_doc_state.len()
        );
        user_service
          .create_collab_object(&collab_object, database_doc_state)
          .await?;

        // sync database's row
        for row_id in row_ids {
          tracing::debug!("sync row: {}", row_id);
          let document_id = database_row_document_id_from_row_id(&row_id);

          let database_row_collab_object = CollabObject::new(
            uid,
            row_id,
            CollabType::DatabaseRow,
            workspace_id.to_string(),
            device_id.clone(),
          );
          let database_row_doc_state =
            get_collab_doc_state(uid, &database_row_collab_object, &collab_db)?;
          tracing::info!(
            "sync object: {} with update: {}",
            database_row_collab_object,
            database_row_doc_state.len()
          );

          let _ = user_service
            .create_collab_object(&database_row_collab_object, database_row_doc_state)
            .await;

          let database_row_document = CollabObject::new(
            uid,
            document_id,
            CollabType::Document,
            workspace_id.to_string(),
            device_id.to_string(),
          );
          // sync document in the row if exist
          if let Ok(document_doc_state) =
            get_collab_doc_state(uid, &database_row_document, &collab_db)
          {
            tracing::info!(
              "sync database row document: {} with update: {}",
              database_row_document,
              document_doc_state.len()
            );
            let _ = user_service
              .create_collab_object(&database_row_document, document_doc_state)
              .await;
          }
        }
      },
      ViewLayout::Chat => {},
    }

    tokio::task::yield_now().await;

    let child_views = folder.lock().get_views_belong_to(&view.id);
    for child_view in child_views {
      let cloned_child_view = child_view.clone();
      if let Err(err) = Box::pin(sync_view(
        uid,
        folder.clone(),
        database_metas.clone(),
        workspace_id.clone(),
        device_id.to_string(),
        child_view,
        collab_db.clone(),
        user_service.clone(),
      ))
      .await
      {
        tracing::error!(
          "🔴sync {:?}:{} failed: {:?}",
          cloned_child_view.layout,
          cloned_child_view.id,
          err
        )
      }
      tokio::task::yield_now().await;
    }
    Ok(())
  })
}

fn get_collab_doc_state(
  uid: i64,
  collab_object: &CollabObject,
  collab_db: &Arc<CollabKVDB>,
) -> Result<Vec<u8>, PersistenceError> {
  let mut collab = Collab::new(uid, &collab_object.object_id, "phantom", vec![], false);
  collab_db.read_txn().load_doc_with_txn(
    uid,
    &collab_object.object_id,
    &mut collab.transact_mut(),
  )?;
  let doc_state = collab
    .encode_collab_v1(|_| Ok::<(), PersistenceError>(()))?
    .doc_state;
  if doc_state.is_empty() {
    return Err(PersistenceError::UnexpectedEmptyUpdates);
  }

  Ok(doc_state.to_vec())
}

fn get_database_doc_state(
  uid: i64,
  collab_object: &CollabObject,
  collab_db: &Arc<CollabKVDB>,
) -> Result<(Vec<u8>, Vec<String>), PersistenceError> {
  let mut collab = Collab::new(uid, &collab_object.object_id, "phantom", vec![], false);
  collab_db.read_txn().load_doc_with_txn(
    uid,
    &collab_object.object_id,
    &mut collab.transact_mut(),
  )?;

  let row_ids = get_database_row_ids(&collab).unwrap_or_default();
  let doc_state = collab
    .encode_collab_v1(|_| Ok::<(), PersistenceError>(()))?
    .doc_state;
  if doc_state.is_empty() {
    return Err(PersistenceError::UnexpectedEmptyUpdates);
  }

  Ok((doc_state.to_vec(), row_ids))
}

async fn sync_folder(
  uid: i64,
  workspace_id: &str,
  device_id: &str,
  collab_db: &Arc<CollabKVDB>,
  user_service: Arc<dyn UserCloudService>,
) -> Result<MutexFolder, Error> {
  let (folder, update) = {
    let mut collab = Collab::new(uid, workspace_id, "phantom", vec![], false);
    // Use the temporary result to short the lifetime of the TransactionMut
    collab_db
      .read_txn()
      .load_doc_with_txn(uid, workspace_id, &mut collab.transact_mut())?;
    let doc_state = collab
      .encode_collab_v1(|_| Ok::<(), PersistenceError>(()))?
      .doc_state;
    (
      MutexFolder::new(Folder::open(uid, collab, None)?),
      doc_state,
    )
  };

  let collab_object = CollabObject::new(
    uid,
    workspace_id.to_string(),
    CollabType::Folder,
    workspace_id.to_string(),
    device_id.to_string(),
  );
  tracing::info!(
    "sync object: {} with update: {}",
    collab_object,
    update.len()
  );
  if let Err(err) = user_service
    .create_collab_object(&collab_object, update.to_vec())
    .await
  {
    tracing::error!("🔴sync folder failed: {:?}", err);
  }

  Ok(folder)
}

async fn sync_database_views(
  uid: i64,
  workspace_id: &str,
  device_id: &str,
  database_views_aggregate_id: &str,
  collab_db: &Arc<CollabKVDB>,
  user_service: Arc<dyn UserCloudService>,
) -> Vec<Arc<DatabaseMeta>> {
  let collab_object = CollabObject::new(
    uid,
    database_views_aggregate_id.to_string(),
    CollabType::WorkspaceDatabase,
    workspace_id.to_string(),
    device_id.to_string(),
  );

  // Use the temporary result to short the lifetime of the TransactionMut
  let mut collab = Collab::new(uid, database_views_aggregate_id, "phantom", vec![], false);
  let meta_list = DatabaseMetaList::new(&mut collab);
  let mut txn = collab.transact_mut();
  match collab_db
    .read_txn()
    .load_doc_with_txn(uid, database_views_aggregate_id, &mut txn)
  {
    Ok(_) => {
      let records = meta_list.get_all_database_meta(&txn);
      let doc_state = txn.encode_state_as_update_v2(&StateVector::default());
      let _ = user_service
        .create_collab_object(&collab_object, doc_state.to_vec())
        .await;
      records.into_iter().map(Arc::new).collect()
    },
    Err(e) => {
      tracing::error!("load doc {} failed: {:?}", database_views_aggregate_id, e);
      vec![]
    },
  }
}

struct MutexFolder(Mutex<Folder>);
impl MutexFolder {
  pub fn new(folder: Folder) -> Self {
    Self(Mutex::new(folder))
  }
}
impl Deref for MutexFolder {
  type Target = Mutex<Folder>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}
unsafe impl Sync for MutexFolder {}
unsafe impl Send for MutexFolder {}

fn collab_type_from_view_layout(view_layout: &ViewLayout) -> CollabType {
  match view_layout {
    ViewLayout::Document => CollabType::Document,
    ViewLayout::Grid | ViewLayout::Board | ViewLayout::Calendar => CollabType::Database,
    ViewLayout::Chat => CollabType::Unknown,
  }
}

fn object_id_from_view(
  view: &Arc<View>,
  database_records: &[Arc<DatabaseMeta>],
) -> Result<String, Error> {
  if view.layout.is_database() {
    match database_records
      .iter()
      .find(|record| record.linked_views.contains(&view.id))
    {
      None => Err(anyhow!(
        "🔴sync view: {} failed: no database for this view",
        view.id
      )),
      Some(record) => Ok(record.database_id.clone()),
    }
  } else {
    Ok(view.id.clone())
  }
}
