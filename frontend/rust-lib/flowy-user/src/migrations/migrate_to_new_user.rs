use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

use appflowy_integrate::{PersistenceError, RocksCollabDB, YrsDocAction};
use collab::core::collab::{CollabRawData, MutexCollab};
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;
use collab_database::database::{is_database_collab, update_database_row_ids};
use collab_database::rows::{database_row_document_id_from_row_id, RowId};
use collab_database::user::DatabaseWithViewsArray;
use collab_folder::core::Folder;

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
) -> FlowyResult<OldToNewIdMap> {
  let old_to_new_id_map = new_collab_db
    .with_write_txn(|w_txn| {
      let old_read_txn = old_collab_db.read_txn();

      let folder_update = old_read_txn.get_all_updates(
        old_user.session.user_id,
        &old_user.session.user_workspace.id,
      )?;
      tracing::debug!(
        "migrate folder: {:?}, number of updates: {}",
        old_user.session.user_workspace.id,
        folder_update.len()
      );

      // Migrates the folder, replacing all existing view IDs with new ones.
      // This function handles the process of migrating folder data between two users. As a part of this migration,
      // all existing view IDs associated with the old user will be replaced by new IDs relevant to the new user.
      let mut old_to_new_id_map = migrate_workspace_folder(
        old_user.session.user_id,
        &old_user.session.user_workspace.id,
        new_user.session.user_id,
        &new_user.session.user_workspace.id,
        folder_update,
        w_txn,
      )
      .unwrap_or_default();

      let database_with_views_update = old_read_txn.get_all_updates(
        old_user.session.user_id,
        &old_user.session.user_workspace.database_views_aggregate_id,
      )?;

      migrate_database_with_views_object(
        &mut old_to_new_id_map,
        old_user.session.user_id,
        &old_user.session.user_workspace.database_views_aggregate_id,
        new_user.session.user_id,
        &new_user.session.user_workspace.database_views_aggregate_id,
        database_with_views_update,
        w_txn,
      );

      let mut object_ids = old_read_txn
        .get_all_docs()
        .map(|iter| iter.collect::<Vec<String>>())
        .unwrap_or_default();

      // Migration of all objects except the folder and database_with_views
      object_ids.retain(|id| {
        id != &old_user.session.user_workspace.id
          && id != &old_user.session.user_workspace.database_views_aggregate_id
      });

      tracing::info!("migrate collab objects: {:?}", object_ids.len());

      let mut collab_by_oid = HashMap::new();
      for object_id in &object_ids {
        let collab = Collab::new(old_user.session.user_id, &object_id, "phantom", vec![]);
        match collab.with_origin_transact_mut(|txn| {
          old_read_txn.load_doc(old_user.session.user_id, &object_id, txn)
        }) {
          Ok(_) => {
            collab_by_oid.insert(object_id.clone(), collab);
          },
          Err(err) => tracing::error!("🔴Initialize migration collab failed: {:?} ", err),
        }
      }

      // Migrate databases
      let mut database_object_ids = vec![];
      for object_id in &object_ids {
        if let Some(collab) = collab_by_oid.get(object_id) {
          if is_database_collab(&collab) {
            database_object_ids.push(object_id.clone());

            update_database_row_ids(&collab, |row_order| {
              let old_row_id = String::from(row_order.id.clone());
              let old_row_document_id = database_row_document_id_from_row_id(&old_row_id);

              let new_row_id = old_to_new_id_map.get_new_id(row_order.id.as_ref());
              let new_row_document_id = database_row_document_id_from_row_id(&new_row_id);

              old_to_new_id_map
                .0
                .insert(old_row_document_id, new_row_document_id);
              tracing::info!("migrate row id: {} to {}", row_order.id, new_row_id);
              row_order.id = RowId::from(new_row_id);
            });

            let new_object_id = old_to_new_id_map.get_new_id(&object_id);
            tracing::debug!(
              "migrate database from: {}, to: {}",
              object_id,
              new_object_id,
            );
            migrate_collab_object(&collab, new_user.session.user_id, &new_object_id, w_txn);
          }
        }
      }

      object_ids.retain(|id| !database_object_ids.contains(id));
      // Migrate other collab objects
      for object_id in &object_ids {
        if let Some(collab) = collab_by_oid.get(object_id) {
          let new_object_id = old_to_new_id_map.get_new_id(&object_id);
          tracing::debug!("migrate from: {}, to: {}", object_id, new_object_id,);
          migrate_collab_object(&collab, new_user.session.user_id, &new_object_id, w_txn);
        }
      }

      Ok(old_to_new_id_map)
    })
    .map_err(|err| FlowyError::new(ErrorCode::Internal, err))?;

  Ok(old_to_new_id_map)
}

#[derive(Debug, Default)]
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

fn migrate_database_with_views_object<'a, W>(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_uid: i64,
  old_object_id: &str,
  new_uid: i64,
  new_object_id: &str,
  updates: CollabRawData,
  w_txn: &'a W,
) where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let origin = CollabOrigin::Client(CollabClient::new(old_uid, "phantom"));
  match Collab::new_with_raw_data(origin, old_object_id, updates, vec![]) {
    Ok(collab) => {
      let database_with_views = DatabaseWithViewsArray::from_collab(&collab);
      for database_view in database_with_views.get_all_databases() {
        database_with_views.update_database(&database_view.database_id, |update| {
          let new_linked_views = update
            .linked_views
            .iter()
            .map(|view_id| old_to_new_id_map.get_new_id(&view_id))
            .collect();
          update.database_id = old_to_new_id_map.get_new_id(&update.database_id);
          update.linked_views = new_linked_views;
        })
      }

      let txn = collab.transact();
      if let Err(err) = w_txn.create_new_doc(new_uid, new_object_id, &txn) {
        tracing::error!("🔴migrate database storage failed: {:?}", err);
      }
      drop(txn);
    },
    Err(err) => tracing::error!("🔴construct migration database storage failed: {:?} ", err),
  }
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
  old_uid: i64,
  old_workspace_id: &str,
  new_uid: i64,
  new_workspace_id: &str,
  updates: CollabRawData,
  w_txn: &'a W,
) -> Option<OldToNewIdMap>
where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let origin = CollabOrigin::Client(CollabClient::new(old_uid, "phantom"));
  let old_folder_collab =
    Collab::new_with_raw_data(origin, old_workspace_id, updates, vec![]).ok()?;
  let old_folder = Folder::open(Arc::new(MutexCollab::from_collab(old_folder_collab)), None);

  let mut folder_data = old_folder.get_folder_data()?;
  let old_workspace_id = folder_data.current_workspace_id;
  folder_data.current_workspace_id = new_workspace_id.to_string();

  let mut workspace = folder_data.workspaces.pop()?;
  if folder_data.workspaces.len() > 1 {
    tracing::error!("🔴migrate folder: more than one workspace");
  }
  workspace.id = new_workspace_id.to_string();

  // Only take one workspace
  folder_data.workspaces.clear();
  folder_data.workspaces.push(workspace);

  let mut old_to_new_id_map: OldToNewIdMap = OldToNewIdMap::new();
  old_to_new_id_map
    .0
    .insert(old_workspace_id.to_string(), new_workspace_id.to_string());

  // 1. Replace the workspace views id to new id
  folder_data.workspaces.iter_mut().for_each(|workspace| {
    workspace
      .child_views
      .iter_mut()
      .for_each(|view_identifier| {
        view_identifier.id = old_to_new_id_map.get_new_id(&view_identifier.id);
      });
  });

  folder_data.views.iter_mut().for_each(|view| {
    // 2. replace the old parent view id of the view
    if let Some(new_parent_view_id) = old_to_new_id_map.get(&view.parent_view_id) {
      view.parent_view_id = new_parent_view_id.clone();
    }

    // 3. replace the old id of the view
    view.id = old_to_new_id_map.get_new_id(&view.id);

    // 4. replace the old id of the children views
    view.children.iter_mut().for_each(|view_identifier| {
      view_identifier.id = old_to_new_id_map.get_new_id(&view_identifier.id);
    });
  });

  folder_data.current_view = old_to_new_id_map
    .get(&folder_data.current_view)
    .cloned()
    .unwrap_or_default();

  let origin = CollabOrigin::Client(CollabClient::new(new_uid, "phantom"));
  let new_folder_collab =
    Collab::new_with_raw_data(origin, new_workspace_id, vec![], vec![]).ok()?;
  let mutex_collab = Arc::new(MutexCollab::from_collab(new_folder_collab));
  let _ = Folder::create(mutex_collab.clone(), None, Some(folder_data));

  {
    let mutex_collab = mutex_collab.lock();
    let txn = mutex_collab.transact();
    if let Err(err) = w_txn.create_new_doc(new_uid, new_workspace_id, &txn) {
      tracing::error!("🔴migrate folder failed: {:?}", err);
    }
  }

  Some(old_to_new_id_map)
}
