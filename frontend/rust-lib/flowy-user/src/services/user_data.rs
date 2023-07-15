use std::sync::Arc;

use appflowy_integrate::{RocksCollabDB, YrsDocAction};
use collab::core::collab::MutexCollab;
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;

use collab_folder::core::{Folder, FolderData};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};

pub struct UserDataMigration();

impl UserDataMigration {
  pub fn migration(
    old_uid: i64,
    old_collab_db: &Arc<RocksCollabDB>,
    old_workspace_id: &str,
    new_uid: i64,
    new_collab_db: &Arc<RocksCollabDB>,
    new_workspace_id: &str,
  ) -> FlowyResult<Option<FolderData>> {
    let mut folder_data = None;
    new_collab_db
      .with_write_txn(|w_txn| {
        let read_txn = old_collab_db.read_txn();
        if let Ok(object_ids) = read_txn.get_all_docs() {
          // Migration of all objects
          for object_id in object_ids {
            tracing::debug!("migrate object: {:?}", object_id);
            if let Ok(updates) = read_txn.get_all_updates(old_uid, &object_id) {
              // If the object is a folder, migrate the folder data
              if object_id == old_workspace_id {
                let origin = CollabOrigin::Client(CollabClient::new(old_uid, ""));
                if let Ok(old_folder_collab) =
                  Collab::new_with_raw_data(origin, &object_id, updates, vec![])
                {
                  let mutex_collab = Arc::new(MutexCollab::from_collab(old_folder_collab));
                  let old_folder = Folder::open(mutex_collab, None);
                  folder_data = migrate_folder(new_workspace_id, old_folder);
                }
              } else {
                let origin = CollabOrigin::Client(CollabClient::new(new_uid, ""));
                match Collab::new_with_raw_data(origin, &object_id, updates, vec![]) {
                  Ok(collab) => {
                    let txn = collab.transact();
                    if let Err(err) = w_txn.create_new_doc(new_uid, &object_id, &txn) {
                      tracing::error!("🔴migrate collab failed: {:?}", err);
                    }
                  },
                  Err(err) => tracing::error!("🔴construct migration collab failed: {:?} ", err),
                }
              }
            }
          }
        }
        Ok(())
      })
      .map_err(|err| FlowyError::new(ErrorCode::Internal, err))?;
    Ok(folder_data)
  }
}

fn migrate_folder(new_workspace_id: &str, old_folder: Folder) -> Option<FolderData> {
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

// fn open_collab_db(uid: i64, root: String) -> FlowyResult<RocksCollabDB> {
//   let dir = collab_db_path_from_uid(&root, uid);
//   RocksCollabDB::open(dir).map_err(|err| FlowyError::new(ErrorCode::Internal, err))
// }
