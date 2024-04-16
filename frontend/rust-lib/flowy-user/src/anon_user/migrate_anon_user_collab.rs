use std::collections::{HashMap, HashSet};
use std::ops::{Deref, DerefMut};
use std::sync::Arc;

use anyhow::anyhow;
use collab::core::collab::{DataSource, MutexCollab};
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;
use collab_database::database::{
  is_database_collab, mut_database_views_with_collab, reset_inline_view_id,
};
use collab_database::rows::{database_row_document_id_from_row_id, mut_row_with_collab, RowId};
use collab_database::workspace_database::DatabaseMetaList;
use collab_folder::{Folder, UserId};
use collab_plugins::local_storage::kv::KVTransactionDB;
use parking_lot::{Mutex, RwLock};
use tracing::info;

use collab_integrate::{CollabKVAction, CollabKVDB, PersistenceError};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_pub::cloud::gen_view_id;

use crate::migrations::AnonUser;
use flowy_user_pub::session::Session;

/// Migration the collab objects of the old user to new user. Currently, it only happens when
/// the user is a local user and try to use AppFlowy cloud service.
pub fn migration_anon_user_on_sign_up(
  old_user: &AnonUser,
  old_collab_db: &Arc<CollabKVDB>,
  new_user_session: &Session,
  new_collab_db: &Arc<CollabKVDB>,
) -> FlowyResult<()> {
  new_collab_db
    .with_write_txn(|new_collab_w_txn| {
      let old_collab_r_txn = old_collab_db.read_txn();
      let old_to_new_id_map = Arc::new(Mutex::new(OldToNewIdMap::new()));
      migrate_user_awareness(
        old_to_new_id_map.lock().deref_mut(),
        old_user,
        new_user_session,
      )?;

      migrate_database_with_views_object(
        &mut old_to_new_id_map.lock(),
        old_user,
        &old_collab_r_txn,
        new_user_session,
        new_collab_w_txn,
      )?;

      let mut object_ids = old_collab_r_txn
        .get_all_docs()
        .map(|iter| iter.collect::<Vec<String>>())
        .unwrap_or_default();

      // Migration of all objects except the folder and database_with_views
      object_ids.retain(|id| {
        id != &old_user.session.user_workspace.id
          && id != &old_user.session.user_workspace.workspace_database_object_id
      });

      info!("migrate collab objects: {:?}", object_ids.len());
      let collab_by_oid = make_collab_by_oid(old_user, &old_collab_r_txn, &object_ids);
      migrate_databases(
        &old_to_new_id_map,
        new_user_session,
        new_collab_w_txn,
        &mut object_ids,
        &collab_by_oid,
      )?;

      // Migrates the folder, replacing all existing view IDs with new ones.
      // This function handles the process of migrating folder data between two users. As a part of this migration,
      // all existing view IDs associated with the old user will be replaced by new IDs relevant to the new user.
      migrate_workspace_folder(
        &mut old_to_new_id_map.lock(),
        old_user,
        &old_collab_r_txn,
        new_user_session,
        new_collab_w_txn,
      )?;

      // Migrate other collab objects
      for object_id in &object_ids {
        if let Some(collab) = collab_by_oid.get(object_id) {
          let new_object_id = old_to_new_id_map.lock().get_new_id(object_id);
          tracing::debug!("migrate from: {}, to: {}", object_id, new_object_id,);
          migrate_collab_object(
            collab,
            new_user_session.user_id,
            &new_object_id,
            new_collab_w_txn,
          );
        }
      }

      Ok(())
    })
    .map_err(|err| FlowyError::new(ErrorCode::Internal, err))?;

  Ok(())
}

#[derive(Default)]
pub struct OldToNewIdMap(HashMap<String, String>);

impl OldToNewIdMap {
  fn new() -> Self {
    Self::default()
  }
  fn get_new_id(&mut self, old_id: &str) -> String {
    let view_id = self
      .0
      .entry(old_id.to_string())
      .or_insert(gen_view_id().to_string());
    (*view_id).clone()
  }
}

impl Deref for OldToNewIdMap {
  type Target = HashMap<String, String>;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl DerefMut for OldToNewIdMap {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

fn migrate_database_with_views_object<'a, 'b, W, R>(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_user: &AnonUser,
  old_collab_r_txn: &R,
  new_user_session: &Session,
  new_collab_w_txn: &W,
) -> Result<(), PersistenceError>
where
  'a: 'b,
  W: CollabKVAction<'a>,
  R: CollabKVAction<'b>,
  PersistenceError: From<W::Error>,
  PersistenceError: From<R::Error>,
{
  let database_with_views_collab = Collab::new(
    old_user.session.user_id,
    &old_user.session.user_workspace.workspace_database_object_id,
    "phantom",
    vec![],
    false,
  );
  database_with_views_collab.with_origin_transact_mut(|txn| {
    old_collab_r_txn.load_doc_with_txn(
      old_user.session.user_id,
      &old_user.session.user_workspace.workspace_database_object_id,
      txn,
    )
  })?;

  let new_uid = new_user_session.user_id;
  let new_object_id = &new_user_session.user_workspace.workspace_database_object_id;

  let array = DatabaseMetaList::from_collab(&database_with_views_collab);
  for database_meta in array.get_all_database_meta() {
    array.update_database(&database_meta.database_id, |update| {
      let new_linked_views = update
        .linked_views
        .iter()
        .map(|view_id| old_to_new_id_map.get_new_id(view_id))
        .collect();
      update.database_id = old_to_new_id_map.get_new_id(&update.database_id);
      update.linked_views = new_linked_views;
    })
  }

  let txn = database_with_views_collab.transact();
  if let Err(err) = new_collab_w_txn.create_new_doc(new_uid, new_object_id, &txn) {
    tracing::error!("🔴migrate database storage failed: {:?}", err);
  }
  drop(txn);
  Ok(())
}

fn migrate_collab_object<'a, W>(collab: &Collab, new_uid: i64, new_object_id: &str, w_txn: &'a W)
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  let txn = collab.transact();
  if let Err(err) = w_txn.create_new_doc(new_uid, &new_object_id, &txn) {
    tracing::error!("🔴migrate collab failed: {:?}", err);
  }
}

fn migrate_workspace_folder<'a, 'b, W, R>(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_user: &AnonUser,
  old_collab_r_txn: &R,
  new_user_session: &Session,
  new_collab_w_txn: &W,
) -> Result<(), PersistenceError>
where
  'a: 'b,
  W: CollabKVAction<'a>,
  R: CollabKVAction<'b>,
  PersistenceError: From<W::Error>,
  PersistenceError: From<R::Error>,
{
  let old_uid = old_user.session.user_id;
  let old_workspace_id = &old_user.session.user_workspace.id;
  let new_uid = new_user_session.user_id;
  let new_workspace_id = &new_user_session.user_workspace.id;

  let old_folder_collab = Collab::new(old_uid, old_workspace_id, "phantom", vec![], false);
  old_folder_collab.with_origin_transact_mut(|txn| {
    old_collab_r_txn.load_doc_with_txn(old_uid, old_workspace_id, txn)
  })?;
  let old_user_id = UserId::from(old_uid);
  let old_folder = Folder::open(
    old_user_id.clone(),
    Arc::new(MutexCollab::new(old_folder_collab)),
    None,
  )
  .map_err(|err| PersistenceError::InvalidData(err.to_string()))?;
  let mut folder_data = old_folder
    .get_folder_data()
    .ok_or(PersistenceError::Internal(anyhow!(
      "Can't migrate the folder data"
    )))?;

  if let Some(old_fav_map) = folder_data.favorites.remove(&old_user_id) {
    let fav_map = old_fav_map
      .into_iter()
      .map(|mut item| {
        let new_view_id = old_to_new_id_map.get_new_id(&item.id);
        item.id = new_view_id;
        item
      })
      .collect();
    folder_data.favorites.insert(UserId::from(new_uid), fav_map);
  }
  if let Some(old_trash_map) = folder_data.trash.remove(&old_user_id) {
    let trash_map = old_trash_map
      .into_iter()
      .map(|mut item| {
        let new_view_id = old_to_new_id_map.get_new_id(&item.id);
        item.id = new_view_id;
        item
      })
      .collect();
    folder_data.trash.insert(UserId::from(new_uid), trash_map);
  }

  if let Some(old_recent_map) = folder_data.recent.remove(&old_user_id) {
    let recent_map = old_recent_map
      .into_iter()
      .map(|mut item| {
        let new_view_id = old_to_new_id_map.get_new_id(&item.id);
        item.id = new_view_id;
        item
      })
      .collect();
    folder_data.recent.insert(UserId::from(new_uid), recent_map);
  }

  old_to_new_id_map
    .0
    .insert(old_workspace_id.to_string(), new_workspace_id.to_string());

  // 1. Replace the workspace views id to new id
  folder_data.workspace.id = new_workspace_id.clone();
  folder_data
    .workspace
    .child_views
    .iter_mut()
    .for_each(|view_identifier| {
      view_identifier.id = old_to_new_id_map.get_new_id(&view_identifier.id);
    });

  folder_data.views.iter_mut().for_each(|view| {
    // 2. replace the old parent view id of the view
    view.parent_view_id = old_to_new_id_map.get_new_id(&view.parent_view_id);

    // 3. replace the old id of the view
    view.id = old_to_new_id_map.get_new_id(&view.id);

    // 4. replace the old id of the children views
    view.children.iter_mut().for_each(|view_identifier| {
      view_identifier.id = old_to_new_id_map.get_new_id(&view_identifier.id);
    });
  });

  match old_to_new_id_map.get(&folder_data.current_view) {
    Some(new_view_id) => {
      folder_data.current_view = new_view_id.clone();
    },
    None => {
      tracing::error!("🔴migrate folder: current view id not found");
      folder_data.current_view = "".to_string();
    },
  }

  let origin = CollabOrigin::Client(CollabClient::new(new_uid, "phantom"));
  let new_folder_collab =
    Collab::new_with_source(origin, new_workspace_id, DataSource::Disk, vec![], false)
      .map_err(|err| PersistenceError::Internal(err.into()))?;
  let mutex_collab = Arc::new(MutexCollab::new(new_folder_collab));
  let new_user_id = UserId::from(new_uid);
  info!("migrated folder: {:?}", folder_data);
  let _ = Folder::create(new_user_id, mutex_collab.clone(), None, folder_data);

  {
    let mutex_collab = mutex_collab.lock();
    let txn = mutex_collab.transact();
    if let Err(err) = new_collab_w_txn.create_new_doc(new_uid, new_workspace_id, &txn) {
      tracing::error!("🔴migrate folder failed: {:?}", err);
    }
  }
  Ok(())
}

fn migrate_user_awareness(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_user: &AnonUser,
  new_user_session: &Session,
) -> Result<(), PersistenceError> {
  let old_uid = old_user.session.user_id;
  let new_uid = new_user_session.user_id;
  tracing::debug!("migrate user awareness from: {}, to: {}", old_uid, new_uid);
  old_to_new_id_map.insert(old_uid.to_string(), new_uid.to_string());
  Ok(())
}

fn migrate_databases<'a, W>(
  old_to_new_id_map: &Arc<Mutex<OldToNewIdMap>>,
  new_user_session: &Session,
  new_collab_w_txn: &'a W,
  object_ids: &mut Vec<String>,
  collab_by_oid: &HashMap<String, Collab>,
) -> Result<(), PersistenceError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  // Migrate databases
  let mut database_object_ids = vec![];
  let database_row_object_ids = RwLock::new(HashSet::new());

  for object_id in &mut *object_ids {
    if let Some(collab) = collab_by_oid.get(object_id) {
      if !is_database_collab(collab) {
        continue;
      }

      database_object_ids.push(object_id.clone());
      reset_inline_view_id(collab, |old_inline_view_id| {
        old_to_new_id_map.lock().get_new_id(&old_inline_view_id)
      });

      mut_database_views_with_collab(collab, |database_view| {
        let new_view_id = old_to_new_id_map.lock().get_new_id(&database_view.id);
        let new_database_id = old_to_new_id_map
          .lock()
          .get_new_id(&database_view.database_id);

        tracing::trace!(
          "migrate database view id from: {}, to: {}",
          database_view.id,
          new_view_id,
        );
        tracing::trace!(
          "migrate database view database id from: {}, to: {}",
          database_view.database_id,
          new_database_id,
        );

        database_view.id = new_view_id;
        database_view.database_id = new_database_id;
        database_view.row_orders.iter_mut().for_each(|row_order| {
          let old_row_id = String::from(row_order.id.clone());
          let old_row_document_id = database_row_document_id_from_row_id(&old_row_id);
          let new_row_id = old_to_new_id_map.lock().get_new_id(&old_row_id);
          let new_row_document_id = database_row_document_id_from_row_id(&new_row_id);
          tracing::debug!("migrate row id: {} to {}", row_order.id, new_row_id);
          tracing::debug!(
            "migrate row document id: {} to {}",
            old_row_document_id,
            new_row_document_id
          );
          old_to_new_id_map
            .lock()
            .insert(old_row_document_id, new_row_document_id);

          row_order.id = RowId::from(new_row_id);
          database_row_object_ids.write().insert(old_row_id);
        });
      });

      let new_object_id = old_to_new_id_map.lock().get_new_id(object_id);
      tracing::debug!(
        "migrate database from: {}, to: {}",
        object_id,
        new_object_id,
      );
      migrate_collab_object(
        collab,
        new_user_session.user_id,
        &new_object_id,
        new_collab_w_txn,
      );
    }
  }
  object_ids.retain(|id| !database_object_ids.contains(id));

  let database_row_object_ids = database_row_object_ids.read();
  for object_id in &*database_row_object_ids {
    if let Some(collab) = collab_by_oid.get(object_id) {
      let new_object_id = old_to_new_id_map.lock().get_new_id(object_id);
      tracing::info!(
        "migrate database row from: {}, to: {}",
        object_id,
        new_object_id,
      );
      mut_row_with_collab(collab, |row_update| {
        row_update.set_row_id(RowId::from(new_object_id.clone()));
      });
      migrate_collab_object(
        collab,
        new_user_session.user_id,
        &new_object_id,
        new_collab_w_txn,
      );
    }
  }
  object_ids.retain(|id| !database_row_object_ids.contains(id));

  Ok(())
}

fn make_collab_by_oid<'a, R>(
  old_user: &AnonUser,
  old_collab_r_txn: &R,
  object_ids: &[String],
) -> HashMap<String, Collab>
where
  R: CollabKVAction<'a>,
  PersistenceError: From<R::Error>,
{
  let mut collab_by_oid = HashMap::new();
  for object_id in object_ids {
    let collab = Collab::new(
      old_user.session.user_id,
      object_id,
      "phantom",
      vec![],
      false,
    );
    match collab.with_origin_transact_mut(|txn| {
      old_collab_r_txn.load_doc_with_txn(old_user.session.user_id, &object_id, txn)
    }) {
      Ok(_) => {
        collab_by_oid.insert(object_id.clone(), collab);
      },
      Err(err) => tracing::error!("🔴Initialize migration collab failed: {:?} ", err),
    }
  }

  collab_by_oid
}
