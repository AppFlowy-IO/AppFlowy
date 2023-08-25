use std::future::Future;
use std::ops::Deref;
use std::pin::Pin;
use std::sync::Arc;

use anyhow::{anyhow, Error};
use appflowy_integrate::{CollabObject, CollabType, PersistenceError, RocksCollabDB, YrsDocAction};
use collab::core::collab::{CollabRawData, MutexCollab};
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::preclude::Collab;
use collab_database::database::get_database_row_ids;
use collab_database::user::{get_database_with_views, DatabaseWithViews};
use collab_folder::core::{Folder, View, ViewLayout};
use parking_lot::Mutex;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_deps::cloud::UserCloudService;

use crate::migrations::MigrationUser;

#[tracing::instrument(level = "info", skip_all, err)]
pub async fn sync_user_data_to_cloud(
  user_service: Arc<dyn UserCloudService>,
  new_user: &MigrationUser,
  collab_db: &Arc<RocksCollabDB>,
) -> FlowyResult<()> {
  let workspace_id = new_user.session.user_workspace.id.clone();
  let uid = new_user.session.user_id;
  let folder = Arc::new(sync_folder(uid, &workspace_id, collab_db, user_service.clone()).await?);

  let database_records = sync_database_views(
    uid,
    &workspace_id,
    &new_user.session.user_workspace.database_views_aggregate_id,
    collab_db,
    user_service.clone(),
  )
  .await;

  let views = folder.lock().get_current_workspace_views();
  for view in views {
    let view_id = view.id.clone();
    if let Err(err) = sync_views(
      uid,
      folder.clone(),
      database_records.clone(),
      workspace_id.to_string(),
      view,
      collab_db.clone(),
      user_service.clone(),
    )
    .await
    {
      tracing::error!("🔴sync {} failed: {:?}", view_id, err);
    }
  }
  Ok(())
}

fn sync_views(
  uid: i64,
  folder: Arc<MutexFolder>,
  database_records: Vec<Arc<DatabaseWithViews>>,
  workspace_id: String,
  view: Arc<View>,
  collab_db: Arc<RocksCollabDB>,
  user_service: Arc<dyn UserCloudService>,
) -> Pin<Box<dyn Future<Output = Result<(), Error>> + Send + Sync>> {
  Box::pin(async move {
    let collab_type = collab_type_from_view_layout(&view.layout);
    let object_id = object_id_from_view(&view, &database_records)?;

    let collab_object =
      CollabObject::new(uid, object_id, collab_type).with_workspace_id(workspace_id.to_string());

    match view.layout {
      ViewLayout::Document => {
        let update = get_init_collab_update(uid, &collab_object, &collab_db)?;
        tracing::info!(
          "sync object: {} with update: {}",
          collab_object,
          update.len()
        );
        user_service
          .create_collab_object(&collab_object, update)
          .await?;
      },
      ViewLayout::Grid | ViewLayout::Board | ViewLayout::Calendar => {
        let (database_update, row_ids) = get_database_init_update(uid, &collab_object, &collab_db)?;
        tracing::info!(
          "sync object: {} with update: {}",
          collab_object,
          database_update.len()
        );
        user_service
          .create_collab_object(&collab_object, database_update)
          .await?;

        // sync database's row
        for row_id in row_ids {
          let database_row_collab_object = CollabObject::new(uid, row_id, CollabType::DatabaseRow)
            .with_workspace_id(workspace_id.to_string());
          let database_row_update =
            get_init_collab_update(uid, &database_row_collab_object, &collab_db)?;
          tracing::info!(
            "sync object: {} with update: {}",
            database_row_collab_object,
            database_row_update.len()
          );
          user_service
            .create_collab_object(&database_row_collab_object, database_row_update)
            .await?;
        }
      },
    }

    let child_views = folder.lock().views.get_views_belong_to(&view.id);
    for child_view in child_views {
      let cloned_child_view = child_view.clone();
      if let Err(err) = Box::pin(sync_views(
        uid,
        folder.clone(),
        database_records.clone(),
        workspace_id.clone(),
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
    }
    Ok(())
  })
}

fn get_init_collab_update(
  uid: i64,
  collab_object: &CollabObject,
  collab_db: &Arc<RocksCollabDB>,
) -> Result<Vec<u8>, PersistenceError> {
  let collab = Collab::new(uid, &collab_object.object_id, "phantom", vec![]);
  let _ = collab.with_origin_transact_mut(|txn| {
    collab_db
      .read_txn()
      .load_doc(uid, &collab_object.object_id, txn)
  })?;
  let update = collab.encode_as_update_v1().0;
  if update.is_empty() {
    return Err(PersistenceError::UnexpectedEmptyUpdates);
  }

  Ok(update)
}

fn get_database_init_update(
  uid: i64,
  collab_object: &CollabObject,
  collab_db: &Arc<RocksCollabDB>,
) -> Result<(Vec<u8>, Vec<String>), PersistenceError> {
  let collab = Collab::new(uid, &collab_object.object_id, "phantom", vec![]);
  let _ = collab.with_origin_transact_mut(|txn| {
    collab_db
      .read_txn()
      .load_doc(uid, &collab_object.object_id, txn)
  })?;

  let row_ids = get_database_row_ids(&collab).unwrap_or_default();
  let update = collab.encode_as_update_v1().0;
  if update.is_empty() {
    return Err(PersistenceError::UnexpectedEmptyUpdates);
  }

  Ok((update, row_ids))
}

async fn sync_folder(
  uid: i64,
  workspace_id: &str,
  collab_db: &Arc<RocksCollabDB>,
  user_service: Arc<dyn UserCloudService>,
) -> Result<MutexFolder, Error> {
  let (folder, update) = {
    let collab = Collab::new(uid, workspace_id, "phantom", vec![]);
    // Use the temporary result to short the lifetime of the TransactionMut
    collab.with_origin_transact_mut(|txn| collab_db.read_txn().load_doc(uid, workspace_id, txn))?;
    let update = collab.encode_as_update_v1().0;
    (
      MutexFolder::new(Folder::open(
        Arc::new(MutexCollab::from_collab(collab)),
        None,
      )),
      update,
    )
  };

  let collab_object = CollabObject::new(uid, workspace_id.to_string(), CollabType::Folder)
    .with_workspace_id(workspace_id.to_string());
  tracing::info!(
    "sync object: {} with update: {}",
    collab_object,
    update.len()
  );
  if let Err(err) = user_service
    .create_collab_object(&collab_object, update)
    .await
  {
    tracing::error!("🔴sync folder failed: {:?}", err);
  }

  Ok(folder)
}

async fn sync_database_views(
  uid: i64,
  workspace_id: &str,
  database_views_aggregate_id: &str,
  collab_db: &Arc<RocksCollabDB>,
  user_service: Arc<dyn UserCloudService>,
) -> Vec<Arc<DatabaseWithViews>> {
  let collab_object = CollabObject::new(
    uid,
    database_views_aggregate_id.to_string(),
    CollabType::WorkspaceDatabase,
  )
  .with_workspace_id(workspace_id.to_string());
  let result = {
    let collab = Collab::new(uid, database_views_aggregate_id, "phantom", vec![]);
    // Use the temporary result to short the lifetime of the TransactionMut
    collab
      .with_origin_transact_mut(|txn| {
        collab_db
          .read_txn()
          .load_doc(uid, database_views_aggregate_id, txn)
      })
      .map(|_| {
        (
          get_database_with_views(&collab),
          collab.encode_as_update_v1().0,
        )
      })
  };

  if let Ok((records, update)) = result {
    let _ = user_service
      .create_collab_object(&collab_object, update)
      .await;
    records.into_iter().map(Arc::new).collect()
  } else {
    vec![]
  }
}

/// Migration the collab objects of the old user to new user. Currently, it only happens when
/// the user is a local user and try to use AppFlowy cloud service.
pub fn migration_local_user_data(
  old_user: &MigrationUser,
  old_collab_db: &Arc<RocksCollabDB>,
  new_user: &MigrationUser,
  new_collab_db: &Arc<RocksCollabDB>,
) -> FlowyResult<()> {
  new_collab_db
    .with_write_txn(|w_txn| {
      let old_read_txn = old_collab_db.read_txn();
      if let Ok(object_ids) = old_read_txn.get_all_docs() {
        // Migration of all objects
        for object_id in object_ids {
          if let Ok(updates) = old_read_txn.get_all_updates(old_user.session.user_id, &object_id) {
            tracing::debug!(
              "migrate object: {:?}, number of updates: {}",
              object_id,
              updates.len()
            );
            // If the object is a folder, migrate the folder data
            if object_id == old_user.session.user_workspace.id {
              migrate_folder(
                old_user.session.user_id,
                &object_id,
                new_user.session.user_id,
                &new_user.session.user_workspace.id,
                updates,
                w_txn,
              );
            } else if object_id == old_user.session.user_workspace.database_views_aggregate_id {
              migrate_database_storage(
                old_user.session.user_id,
                &object_id,
                new_user.session.user_id,
                &new_user.session.user_workspace.database_views_aggregate_id,
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

  Ok(())
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
      drop(txn);
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

fn migrate_folder<'a, W>(
  old_uid: i64,
  old_workspace_id: &str,
  new_uid: i64,
  new_workspace_id: &str,
  updates: CollabRawData,
  w_txn: &'a W,
) -> Option<()>
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

  // Update the view's parent view id to new workspace id
  folder_data.views.iter_mut().for_each(|view| {
    if view.parent_view_id == old_workspace_id {
      view.parent_view_id = new_workspace_id.to_string();
    }
  });

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

  None
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
  }
}

fn object_id_from_view(
  view: &Arc<View>,
  database_records: &[Arc<DatabaseWithViews>],
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
