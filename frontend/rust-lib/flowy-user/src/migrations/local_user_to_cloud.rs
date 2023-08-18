use std::sync::Arc;

use appflowy_integrate::{PersistenceError, RocksCollabDB, YrsDocAction};
use collab::core::collab::{CollabRawData, MutexCollab};
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;
use collab_folder::core::{Folder, FolderData};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::migrations::MigrationUser;

/// Migration the collab objects of the old user to new user. Currently, it only happens when
/// the user is a local user and try to use AppFlowy cloud service.
pub fn migration_user_to_cloud(
  old_user: &MigrationUser,
  old_collab_db: &Arc<RocksCollabDB>,
  new_user: &MigrationUser,
  new_collab_db: &Arc<RocksCollabDB>,
) -> FlowyResult<Option<FolderData>> {
  let mut folder_data = None;
  new_collab_db
    .with_write_txn(|w_txn| {
      let read_txn = old_collab_db.read_txn();
      if let Ok(object_ids) = read_txn.get_all_docs() {
        // Migration of all objects
        for object_id in object_ids {
          tracing::debug!("migrate object: {:?}", object_id);
          if let Ok(updates) = read_txn.get_all_updates(old_user.session.user_id, &object_id) {
            // If the object is a folder, migrate the folder data
            if object_id == old_user.session.user_workspace.id {
              folder_data = migrate_folder(
                old_user.session.user_id,
                &object_id,
                &new_user.session.user_workspace.id,
                updates,
              );
            } else if object_id == old_user.session.user_workspace.database_storage_id {
              migrate_database_storage(
                old_user.session.user_id,
                &object_id,
                new_user.session.user_id,
                &new_user.session.user_workspace.database_storage_id,
                updates,
                w_txn,
              );
            } else {
              migrate_object(
                old_user.session.user_id,
                new_user.session.user_id,
                &object_id,
                updates,
                w_txn,
              );
            }
          }
        }
      }
      Ok(())
    })
    .map_err(|err| FlowyError::new(ErrorCode::Internal, err))?;
  Ok(folder_data)
}

fn migrate_database_storage<'a, W>(
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
      let txn = collab.transact();
      if let Err(err) = w_txn.create_new_doc(new_uid, new_object_id, &txn) {
        tracing::error!("🔴migrate database storage failed: {:?}", err);
      }
    },
    Err(err) => tracing::error!("🔴construct migration database storage failed: {:?} ", err),
  }
}

fn migrate_object<'a, W>(
  old_uid: i64,
  new_uid: i64,
  object_id: &str,
  updates: CollabRawData,
  w_txn: &'a W,
) where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let origin = CollabOrigin::Client(CollabClient::new(old_uid, "phantom"));
  match Collab::new_with_raw_data(origin, object_id, updates, vec![]) {
    Ok(collab) => {
      let txn = collab.transact();
      if let Err(err) = w_txn.create_new_doc(new_uid, object_id, &txn) {
        tracing::error!("🔴migrate collab failed: {:?}", err);
      }
    },
    Err(err) => tracing::error!("🔴construct migration collab failed: {:?} ", err),
  }
}

fn migrate_folder(
  old_uid: i64,
  old_object_id: &str,
  new_workspace_id: &str,
  updates: CollabRawData,
) -> Option<FolderData> {
  let origin = CollabOrigin::Client(CollabClient::new(old_uid, "phantom"));
  let old_folder_collab = Collab::new_with_raw_data(origin, old_object_id, updates, vec![]).ok()?;
  let mutex_collab = Arc::new(MutexCollab::from_collab(old_folder_collab));
  let old_folder = Folder::open(mutex_collab, None);

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

  // Update the view's parent view id to new workspace id
  folder_data.views.iter_mut().for_each(|view| {
    if view.parent_view_id == old_workspace_id {
      view.parent_view_id = new_workspace_id.to_string();
    }
  });

  Some(folder_data)
}
