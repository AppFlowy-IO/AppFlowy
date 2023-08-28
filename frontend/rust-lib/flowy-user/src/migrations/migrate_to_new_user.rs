use std::collections::{HashMap, HashSet};
use std::ops::{Deref, DerefMut};
use std::sync::Arc;

use anyhow::anyhow;
use appflowy_integrate::{PersistenceError, RocksCollabDB, YrsDocAction};
use collab::core::collab::MutexCollab;
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;
use collab_database::database::{
  is_database_collab, mut_database_views_with_collab, reset_inline_view_id,
};
use collab_database::rows::{database_row_document_id_from_row_id, mut_row_with_collab, RowId};
use collab_database::user::DatabaseWithViewsArray;
use collab_folder::core::Folder;
use parking_lot::{Mutex, RwLock};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_deps::cloud::gen_view_id;

use crate::migrations::MigrationUser;

/// Migration the collab objects of the old user to new user. Currently, it only happens when
/// the user is a local user and try to use AppFlowy cloud service.
pub fn migration_local_user_on_sign_up(
  old_user: &MigrationUser,
  old_collab_db: &Arc<RocksCollabDB>,
  new_user: &MigrationUser,
  new_collab_db: &Arc<RocksCollabDB>,
) -> FlowyResult<()> {
  new_collab_db
    .with_write_txn(|new_collab_w_txn| {
      let old_collab_r_txn = old_collab_db.read_txn();
      let old_to_new_id_map = Arc::new(Mutex::new(OldToNewIdMap::new()));

      migrate_user_awareness(old_to_new_id_map.lock().deref_mut(), old_user, new_user)?;

      migrate_database_with_views_object(
        &mut old_to_new_id_map.lock(),
        old_user,
        &old_collab_r_txn,
        new_user,
        new_collab_w_txn,
      )?;

      let mut object_ids = old_collab_r_txn
        .get_all_docs()
        .map(|iter| iter.collect::<Vec<String>>())
        .unwrap_or_default();

      // Migration of all objects except the folder and database_with_views
      object_ids.retain(|id| {
        id != &old_user.session.user_workspace.id
          && id != &old_user.session.user_workspace.database_views_aggregate_id
      });

      tracing::info!("migrate collab objects: {:?}", object_ids.len());
      let collab_by_oid = make_collab_by_oid(old_user, &old_collab_r_txn, &object_ids);
      migrate_databases(
        &old_to_new_id_map,
        new_user,
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
        new_user,
        new_collab_w_txn,
      )?;

      // Migrate other collab objects
      for object_id in &object_ids {
        if let Some(collab) = collab_by_oid.get(object_id) {
          let new_object_id = old_to_new_id_map.lock().get_new_id(object_id);
          tracing::debug!("migrate from: {}, to: {}", object_id, new_object_id,);
          migrate_collab_object(
            collab,
            new_user.session.user_id,
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

fn migrate_database_with_views_object<'a, W>(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_user: &MigrationUser,
  old_collab_r_txn: &'a W,
  new_user: &MigrationUser,
  new_collab_w_txn: &'a W,
) -> Result<(), PersistenceError>
where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let database_with_views_collab = Collab::new(
    old_user.session.user_id,
    &old_user.session.user_workspace.database_views_aggregate_id,
    "phantom",
    vec![],
  );
  database_with_views_collab.with_origin_transact_mut(|txn| {
    old_collab_r_txn.load_doc(
      old_user.session.user_id,
      &old_user.session.user_workspace.database_views_aggregate_id,
      txn,
    )
  })?;

  let new_uid = new_user.session.user_id;
  let new_object_id = &new_user.session.user_workspace.database_views_aggregate_id;

  let array = DatabaseWithViewsArray::from_collab(&database_with_views_collab);
  for database_view in array.get_all_databases() {
    array.update_database(&database_view.database_id, |update| {
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
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let txn = collab.transact();
  if let Err(err) = w_txn.create_new_doc(new_uid, &new_object_id, &txn) {
    tracing::error!("🔴migrate collab failed: {:?}", err);
  }
}

fn migrate_workspace_folder<'a, W>(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_user: &MigrationUser,
  old_collab_r_txn: &'a W,
  new_user: &MigrationUser,
  new_collab_w_txn: &'a W,
) -> Result<(), PersistenceError>
where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let old_uid = old_user.session.user_id;
  let old_workspace_id = &old_user.session.user_workspace.id;
  let new_uid = new_user.session.user_id;
  let new_workspace_id = &new_user.session.user_workspace.id;

  let old_folder_collab = Collab::new(old_uid, old_workspace_id, "phantom", vec![]);
  old_folder_collab
    .with_origin_transact_mut(|txn| old_collab_r_txn.load_doc(old_uid, old_workspace_id, txn))?;
  let old_folder = Folder::open(Arc::new(MutexCollab::from_collab(old_folder_collab)), None);
  let mut folder_data = old_folder
    .get_folder_data()
    .ok_or(PersistenceError::Internal(
      anyhow!("Can't migrate the folder data").into(),
    ))?;

  old_to_new_id_map
    .0
    .insert(old_workspace_id.to_string(), new_workspace_id.to_string());

  // 1. Replace the workspace views id to new id
  debug_assert!(folder_data.workspaces.len() == 1);

  folder_data
    .workspaces
    .iter_mut()
    .enumerate()
    .for_each(|(index, workspace)| {
      if index == 0 {
        workspace.id = new_workspace_id.to_string();
      } else {
        tracing::warn!("🔴migrate folder: more than one workspace");
        workspace.id = old_to_new_id_map.get_new_id(&workspace.id);
      }
      workspace
        .child_views
        .iter_mut()
        .for_each(|view_identifier| {
          view_identifier.id = old_to_new_id_map.get_new_id(&view_identifier.id);
        });
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

  match old_to_new_id_map.get(&folder_data.current_workspace_id) {
    Some(new_workspace_id) => {
      folder_data.current_workspace_id = new_workspace_id.clone();
    },
    None => {
      tracing::error!("🔴migrate folder: current workspace id not found");
    },
  }

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
  let new_folder_collab = Collab::new_with_raw_data(origin, new_workspace_id, vec![], vec![])
    .map_err(|err| PersistenceError::Internal(Box::new(err)))?;
  let mutex_collab = Arc::new(MutexCollab::from_collab(new_folder_collab));
  let _ = Folder::create(mutex_collab.clone(), None, Some(folder_data));

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
  old_user: &MigrationUser,
  new_user: &MigrationUser,
) -> Result<(), PersistenceError> {
  let old_uid = old_user.session.user_id;
  let new_uid = new_user.session.user_id;
  tracing::debug!("migrate user awareness from: {}, to: {}", old_uid, new_uid);
  old_to_new_id_map.insert(old_uid.to_string(), new_uid.to_string());
  Ok(())
}

fn migrate_databases<'a, W>(
  old_to_new_id_map: &Arc<Mutex<OldToNewIdMap>>,
  new_user: &MigrationUser,
  new_collab_w_txn: &'a W,
  object_ids: &mut Vec<String>,
  collab_by_oid: &HashMap<String, Collab>,
) -> Result<(), PersistenceError>
where
  W: YrsDocAction<'a>,
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
        new_user.session.user_id,
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
        new_user.session.user_id,
        &new_object_id,
        new_collab_w_txn,
      );
    }
  }
  object_ids.retain(|id| !database_row_object_ids.contains(id));

  Ok(())
}

fn make_collab_by_oid<'a, R>(
  old_user: &MigrationUser,
  old_collab_r_txn: &R,
  object_ids: &[String],
) -> HashMap<String, Collab>
where
  R: YrsDocAction<'a>,
  PersistenceError: From<R::Error>,
{
  let mut collab_by_oid = HashMap::new();
  for object_id in object_ids {
    let collab = Collab::new(old_user.session.user_id, object_id, "phantom", vec![]);
    match collab.with_origin_transact_mut(|txn| {
      old_collab_r_txn.load_doc(old_user.session.user_id, &object_id, txn)
    }) {
      Ok(_) => {
        collab_by_oid.insert(object_id.clone(), collab);
      },
      Err(err) => tracing::error!("🔴Initialize migration collab failed: {:?} ", err),
    }
  }

  collab_by_oid
}
