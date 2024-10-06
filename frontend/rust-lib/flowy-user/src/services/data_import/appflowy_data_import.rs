use crate::migrations::session_migration::migrate_session_with_user_uuid;

use crate::services::data_import::importer::load_collab_by_object_ids;
use crate::services::db::UserDBPath;
use crate::services::entities::UserPaths;
use crate::services::sqlite_sql::user_sql::select_user_profile;
use crate::user_manager::run_collab_data_migration;
use anyhow::anyhow;
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;

use collab::preclude::updates::decoder::Decode;
use collab::preclude::updates::encoder::Encode;
use collab::preclude::{Collab, Doc, ReadTxn, StateVector, Transact, Update};
use collab_database::database::{
  is_database_collab, mut_database_views_with_collab, reset_inline_view_id,
};
use collab_database::rows::{database_row_document_id_from_row_id, mut_row_with_collab, RowId};
use collab_database::workspace_database::WorkspaceDatabaseBody;
use collab_document::document_data::default_document_collab_data;
use collab_entity::CollabType;
use collab_folder::hierarchy_builder::{NestedViews, ParentChildViews, ViewBuilder};
use collab_folder::{Folder, UserId, View, ViewIdentifier, ViewLayout};
use collab_integrate::{CollabKVAction, CollabKVDB, PersistenceError};
use collab_plugins::local_storage::kv::KVTransactionDB;
use flowy_error::FlowyError;
use flowy_folder_pub::cloud::gen_view_id;
use flowy_folder_pub::entities::{
  ImportFrom, ImportedAppFlowyData, ImportedCollabData, ImportedFolderData,
};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams};
use flowy_user_pub::entities::{user_awareness_object_id, Authenticator};
use flowy_user_pub::session::Session;
use rayon::prelude::*;
use std::collections::{HashMap, HashSet};

use std::ops::{Deref, DerefMut};
use std::path::Path;
use std::sync::{Arc, Weak};
use tracing::{error, event, info, instrument, warn};
pub(crate) struct ImportedFolder {
  pub imported_session: Session,
  pub imported_collab_db: Arc<CollabKVDB>,
  pub container_name: Option<String>,
  pub parent_view_id: Option<String>,
  pub source: ImportedSource,
}

#[derive(Clone)]
pub(crate) enum ImportedSource {
  ExternalFolder,
  AnonUser,
}

impl ImportedFolder {
  pub fn with_container_name(mut self, container_name: Option<String>) -> Self {
    self.container_name = container_name;
    self
  }
}

pub(crate) fn prepare_import(
  path: &str,
  parent_view_id: Option<String>,
) -> anyhow::Result<ImportedFolder> {
  info!(
    "[AppflowyData]:importing data from path: {}, parent_view_id:{:?}",
    path, parent_view_id
  );
  if !Path::new(path).exists() {
    return Err(anyhow!("The path: {} is not exist", path));
  }
  let user_paths = UserPaths::new(path.to_string());
  let other_store_preferences = Arc::new(KVStorePreferences::new(path)?);
  migrate_session_with_user_uuid("appflowy_session_cache", &other_store_preferences);
  let imported_session = other_store_preferences
    .get_object::<Session>("appflowy_session_cache")
    .ok_or(anyhow!(
      "Can't find the session cache in the appflowy data folder at path: {}",
      path
    ))?;

  let collab_db_path = user_paths.collab_db_path(imported_session.user_id);
  info!("[AppflowyData]: collab db path: {:?}", collab_db_path);

  let sqlite_db_path = user_paths.sqlite_db_path(imported_session.user_id);
  info!("[AppflowyData]: sqlite db path: {:?}", sqlite_db_path);

  let imported_sqlite_db = flowy_sqlite::init(sqlite_db_path)
    .map_err(|err| anyhow!("[AppflowyData]: open import collab db failed: {:?}", err))?;

  let imported_collab_db = Arc::new(
    CollabKVDB::open(collab_db_path)
      .map_err(|err| anyhow!("[AppflowyData]: open import collab db failed: {:?}", err))?,
  );
  let imported_user = select_user_profile(
    imported_session.user_id,
    imported_sqlite_db.get_connection()?,
  )?;

  run_collab_data_migration(
    &imported_session,
    &imported_user,
    imported_collab_db.clone(),
    imported_sqlite_db.get_pool(),
    None,
  );

  Ok(ImportedFolder {
    imported_session,
    imported_collab_db,
    container_name: None,
    parent_view_id,
    source: ImportedSource::ExternalFolder,
  })
}

#[allow(dead_code)]
fn migrate_user_awareness(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_user_session: &Session,
  new_user_session: &Session,
) -> Result<(), PersistenceError> {
  let old_uid = old_user_session.user_id;
  let new_uid = new_user_session.user_id;
  old_to_new_id_map.insert(old_uid.to_string(), new_uid.to_string());
  Ok(())
}

/// This path refers to the directory where AppFlowy stores its data. The directory structure is as follows:
/// root folder:
///   - cache.db
///   - log (log files with unique identifiers)
///   - 2761499 (other relevant files or directories, identified by unique numbers)

#[instrument(level = "debug", skip_all, err)]
pub(crate) fn generate_import_data(
  current_session: &Session,
  workspace_id: &str,
  user_collab_db: &Arc<CollabKVDB>,
  imported_folder: ImportedFolder,
) -> anyhow::Result<ImportedAppFlowyData> {
  info!(
    "[AppflowyData]:importing workspace: {}:{}",
    imported_folder.imported_session.user_workspace.name,
    imported_folder.imported_session.user_workspace.id,
  );
  let imported_session = imported_folder.imported_session.clone();
  let imported_collab_db = imported_folder.imported_collab_db.clone();
  let imported_container_view_name = imported_folder.container_name.clone();

  let mut database_view_ids_by_database_id: HashMap<String, Vec<String>> = HashMap::new();
  let mut row_object_ids = HashSet::new();
  let mut document_object_ids = HashSet::new();
  let mut database_object_ids = HashSet::new();

  // All the imported views will be attached to the container view. If the container view name is not provided,
  // the container view will be the workspace, which mean the root of the workspace.
  let import_container_view_id = match imported_folder.source {
    ImportedSource::ExternalFolder => match &imported_container_view_name {
      None => workspace_id.to_string(),
      Some(_) => gen_view_id().to_string(),
    },
    ImportedSource::AnonUser => workspace_id.to_string(),
  };

  let (views, orphan_views) = user_collab_db.with_write_txn(|current_collab_db_write_txn| {
    let imported_collab_db_read_txn = imported_collab_db.read_txn();
    // use the old_to_new_id_map to keep track of the other collab object id and the new collab object id
    let mut old_to_new_id_map = OldToNewIdMap::new();

    // 1. Get all the imported collab object ids
    let mut all_imported_object_ids = imported_collab_db_read_txn
      .get_all_docs()
      .map(|iter| iter.collect::<Vec<String>>())
      .unwrap_or_default();

    // when doing import, we don't want to import these objects:
    // 1. user workspace
    // 2. workspace database views
    // 3. user awareness
    // So we remove these object ids from the list
    let user_workspace_id = &imported_session.user_workspace.id;
    let workspace_database_id = &imported_session.user_workspace.workspace_database_id;
    let user_awareness_id =
      user_awareness_object_id(&imported_session.user_uuid, user_workspace_id).to_string();
    all_imported_object_ids.retain(|id| {
      id != user_workspace_id && id != workspace_database_id && id != &user_awareness_id
    });

    // 2. mapping the workspace database ids
    if let Err(err) = mapping_workspace_database_ids(
      &mut old_to_new_id_map,
      &imported_session,
      &imported_collab_db_read_txn,
      &mut database_view_ids_by_database_id,
      &mut database_object_ids,
    ) {
      error!("[AppflowyData]:import workspace database fail: {}", err);
    }

    // remove the database view ids from the object ids. Because there are no physical collab object
    // for the database view
    let database_view_ids: Vec<String> = database_view_ids_by_database_id
      .values()
      .flatten()
      .cloned()
      .collect();
    all_imported_object_ids.retain(|id| !database_view_ids.contains(id));

    // 3. load imported collab objects data.
    let (mut imported_collab_by_oid, invalid_object_ids) = load_collab_by_object_ids(
      imported_session.user_id,
      &imported_collab_db_read_txn,
      &all_imported_object_ids,
    );

    // remove the invalid object ids from the object ids
    info!(
      "[AppflowyData]: invalid object ids: {:?}",
      invalid_object_ids
    );
    all_imported_object_ids.retain(|id| !invalid_object_ids.contains(id));
    // the object ids now only contains the document collab object ids
    all_imported_object_ids.iter().for_each(|object_id| {
      old_to_new_id_map.exchange_new_id(object_id);
    });

    // import the database
    migrate_databases(
      &mut old_to_new_id_map,
      current_session,
      current_collab_db_write_txn,
      &mut all_imported_object_ids,
      &mut imported_collab_by_oid,
      &mut row_object_ids,
    )?;

    // Update the parent view IDs of all top-level views to match the new container view ID, making
    // them child views of the container. This ensures that the hierarchy within the imported
    // structure is correctly maintained.
    let MigrateViews {
      child_views,
      orphan_views,
      mut invalid_orphan_views,
      not_exist_parent_view_ids: _,
    } = migrate_folder_views(
      &import_container_view_id,
      &mut old_to_new_id_map,
      &imported_session,
      &imported_collab_db_read_txn,
      &imported_collab_by_oid,
    )?;

    let gen_collabs = all_imported_object_ids
        .par_iter()
        .filter_map(|object_id| {
          let f = || {
            let imported_collab = imported_collab_by_oid.get(object_id)?;
            let new_object_id = old_to_new_id_map.get_exchanged_id(object_id)?;
            gen_sv_and_doc_state(
              current_session.user_id,
              new_object_id,
              imported_collab,
              CollabType::Document,
            )
          };
          match f() {
            None => {
              warn!(
              "[AppflowyData]: Can't find the new id for the imported object:{}, new object id:{:?}",
              object_id,
              old_to_new_id_map.get_exchanged_id(object_id),
            );
              None
            },
            Some(value) => Some(value),
          }
        })
        .collect::<Vec<_>>();

    for gen_collab in gen_collabs {
      document_object_ids.insert(gen_collab.object_id.clone());
      write_gen_collab(gen_collab, current_collab_db_write_txn);
    }

    let (mut views, orphan_views) = match imported_folder.source {
      ImportedSource::ExternalFolder => match imported_container_view_name {
        None => Ok::<(Vec<ParentChildViews>, Vec<ParentChildViews>), anyhow::Error>((
          child_views,
          orphan_views,
        )),
        Some(container_name) => {
          // create a new view with given name and then attach views to it
          let child_views = vec![create_new_container_view(
            current_session,
            &mut document_object_ids,
            &import_container_view_id,
            current_collab_db_write_txn,
            child_views,
            container_name,
          )?];
          Ok((child_views, orphan_views))
        },
      },
      ImportedSource::AnonUser => Ok((child_views, orphan_views)),
    }?;

    if !invalid_orphan_views.is_empty() {
      let other_view_id = gen_view_id().to_string();
      invalid_orphan_views
        .iter_mut()
        .for_each(|parent_child_views| {
          parent_child_views.view.parent_view_id = other_view_id.clone();
        });
      let mut other_view = create_new_container_view(
        current_session,
        &mut document_object_ids,
        &other_view_id,
        current_collab_db_write_txn,
        invalid_orphan_views,
        "Others".to_string(),
      )?;

      // if the views is empty, the other view is the top level view
      // otherwise, the other view is the child view of the first view
      if views.is_empty() {
        views.push(other_view);
      } else {
        let first_view = views.first_mut().unwrap();
        other_view.view.parent_view_id = first_view.view.id.clone();
        first_view.children.push(other_view);
      }
    }

    Ok((views, orphan_views))
  })?;

  let source = match imported_folder.source {
    ImportedSource::ExternalFolder => ImportFrom::AppFlowyDataFolder,
    ImportedSource::AnonUser => ImportFrom::AnonUser,
  };

  Ok(ImportedAppFlowyData {
    source,
    parent_view_id: imported_folder.parent_view_id,
    folder_data: ImportedFolderData {
      views,
      orphan_views,
      database_view_ids_by_database_id,
    },
    collab_data: ImportedCollabData {
      row_object_ids: row_object_ids.into_iter().collect(),
      database_object_ids: database_object_ids.into_iter().collect(),
      document_object_ids: document_object_ids.into_iter().collect(),
    },
  })
}

#[instrument(level = "debug", skip_all, err)]
fn create_new_container_view<'a, W>(
  current_session: &Session,
  document_object_ids: &mut HashSet<String>,
  import_container_view_id: &str,
  collab_write_txn: &'a W,
  mut child_views: Vec<ParentChildViews>,
  container_name: String,
) -> Result<ParentChildViews, PersistenceError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  child_views.iter_mut().for_each(|parent_child_views| {
    if parent_child_views.view.parent_view_id != import_container_view_id {
      warn!(
        "[AppflowyData]: The parent view id of the child views is not the import container view id: {}",
        import_container_view_id
      );
      parent_child_views.view.parent_view_id = import_container_view_id.to_string();
    }
  });

  let name = if container_name.is_empty() {
    format!(
      "import_{}",
      chrono::Local::now().format("%Y-%m-%d %H:%M:%S")
    )
  } else {
    container_name
  };

  // create the content for the container view
  let import_container_doc_state = default_document_collab_data(import_container_view_id)
    .map_err(|err| PersistenceError::InvalidData(err.to_string()))?
    .doc_state
    .to_vec();

  let collab = Collab::new_with_source(
    CollabOrigin::Empty,
    import_container_view_id,
    DataSource::DocStateV1(import_container_doc_state),
    vec![],
    false,
  )?;
  write_collab_object(
    &collab,
    current_session.user_id,
    import_container_view_id,
    collab_write_txn,
    CollabType::Document,
  );

  document_object_ids.insert(import_container_view_id.to_string());

  let import_container_views = ViewBuilder::new(
    current_session.user_id,
    current_session.user_workspace.id.clone(),
  )
  .with_view_id(import_container_view_id)
  .with_layout(ViewLayout::Document)
  .with_name(&name)
  .with_child_views(child_views)
  .build();

  Ok(import_container_views)
}

#[instrument(level = "debug", skip_all, err)]
fn mapping_workspace_database_ids<'a, W>(
  old_to_new_id_map: &mut OldToNewIdMap,
  imported_session: &Session,
  imported_collab_db_read_txn: &W,
  database_view_ids_by_database_id: &mut HashMap<String, Vec<String>>,
  database_object_ids: &mut HashSet<String>,
) -> Result<(), PersistenceError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  let mut workspace_database_collab = Collab::new(
    imported_session.user_id,
    &imported_session.user_workspace.workspace_database_id,
    "import_device",
    vec![],
    false,
  );
  imported_collab_db_read_txn.load_doc_with_txn(
    imported_session.user_id,
    &imported_session.user_workspace.workspace_database_id,
    &mut workspace_database_collab.transact_mut(),
  )?;

  let workspace_database_body = init_workspace_database_body(
    &imported_session.user_workspace.workspace_database_id,
    workspace_database_collab,
  );
  for database_meta_list in workspace_database_body.get_all_database_meta() {
    database_view_ids_by_database_id.insert(
      old_to_new_id_map.exchange_new_id(&database_meta_list.database_id),
      database_meta_list
        .linked_views
        .into_iter()
        .map(|view_id| old_to_new_id_map.exchange_new_id(&view_id))
        .collect(),
    );
  }
  database_object_ids.extend(
    database_view_ids_by_database_id
      .keys()
      .cloned()
      .collect::<Vec<String>>(),
  );
  Ok(())
}

fn init_workspace_database_body(object_id: &str, collab: Collab) -> WorkspaceDatabaseBody {
  match WorkspaceDatabaseBody::open(collab) {
    Ok(body) => body,
    Err(err) => {
      error!(
        "[AppflowyData]:init workspace database body failed: {:?}, create a new one",
        err
      );
      let collab = Collab::new_with_origin(CollabOrigin::Empty, object_id, vec![], false);
      WorkspaceDatabaseBody::create(collab)
    },
  }
}

#[instrument(level = "debug", skip_all, err)]
fn migrate_databases<'a, W>(
  old_to_new_id_map: &mut OldToNewIdMap,
  session: &Session,
  collab_write_txn: &'a W,
  imported_object_ids: &mut Vec<String>,
  imported_collab_by_oid: &mut HashMap<String, Collab>,
  row_object_ids: &mut HashSet<String>,
) -> Result<(), PersistenceError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  // Migrate databases
  let mut row_document_object_ids = HashSet::new();
  let mut database_object_ids = vec![];
  let mut imported_database_row_object_ids: HashMap<String, HashSet<String>> = HashMap::new();

  for object_id in imported_object_ids.iter() {
    if let Some(database_collab) = imported_collab_by_oid.get_mut(object_id) {
      if !is_database_collab(database_collab) {
        continue;
      }

      database_object_ids.push(object_id.clone());
      reset_inline_view_id(database_collab, |old_inline_view_id| {
        old_to_new_id_map.exchange_new_id(&old_inline_view_id)
      });

      mut_database_views_with_collab(database_collab, |database_view| {
        let new_view_id = old_to_new_id_map.exchange_new_id(&database_view.id);
        let old_database_id = database_view.database_id.clone();
        let new_database_id = old_to_new_id_map.exchange_new_id(&database_view.database_id);

        database_view.id = new_view_id;
        database_view.database_id = new_database_id;
        database_view.row_orders.iter_mut().for_each(|row_order| {
          let old_row_id = String::from(row_order.id.clone());
          let old_row_document_id = database_row_document_id_from_row_id(&old_row_id);
          let new_row_id = old_to_new_id_map.exchange_new_id(&old_row_id);
          // The row document might not exist in the database row. But by querying the old_row_document_id,
          // we can know the document of the row is exist or not.
          let new_row_document_id = database_row_document_id_from_row_id(&new_row_id);
          old_to_new_id_map.insert(old_row_document_id.clone(), new_row_document_id);
          row_order.id = RowId::from(new_row_id);

          imported_database_row_object_ids
            .entry(old_database_id.clone())
            .or_default()
            .insert(old_row_id);
        });

        // collect the ids
        let new_row_ids = database_view
          .row_orders
          .iter()
          .map(|order| order.id.clone().into_inner())
          .collect::<Vec<String>>();
        row_object_ids.extend(new_row_ids);
      });

      let new_object_id = old_to_new_id_map.exchange_new_id(object_id);
      write_collab_object(
        database_collab,
        session.user_id,
        &new_object_id,
        collab_write_txn,
        CollabType::Database,
      );
    }
  }

  // remove the database object ids from the object ids
  imported_object_ids.retain(|id| !database_object_ids.contains(id));

  // remove database row object ids from the imported object ids
  imported_object_ids.retain(|id| {
    !imported_database_row_object_ids
      .values()
      .flatten()
      .any(|row_id| row_id == id)
  });

  for (database_id, imported_row_ids) in imported_database_row_object_ids {
    imported_row_ids.iter().for_each(|imported_row_id| {
      if let Some(imported_collab) = imported_collab_by_oid.get_mut(imported_row_id) {
        let new_database_id = old_to_new_id_map.exchange_new_id(&database_id);
        let new_row_id = old_to_new_id_map.exchange_new_id(imported_row_id);
        mut_row_with_collab(imported_collab, |row_update| {
          row_update
            .set_row_id(RowId::from(new_row_id.clone()))
            .set_database_id(new_database_id.clone());
        });
      }

      // imported_collab_by_oid contains all the collab object ids, including the row document collab object ids.
      // So, if the id exist in the imported_collab_by_oid, it means the row document collab object is exist.
      let imported_row_document_id = database_row_document_id_from_row_id(imported_row_id);
      if imported_collab_by_oid
        .get(&imported_row_document_id)
        .is_some()
      {
        let new_row_document_id = old_to_new_id_map.exchange_new_id(&imported_row_document_id);
        row_document_object_ids.insert(new_row_document_id);
      }
    });

    let gen_collabs = imported_row_ids
      .par_iter()
      .filter_map(|imported_row_id| {
        let imported_collab = imported_collab_by_oid.get(imported_row_id)?;
        match old_to_new_id_map.get_exchanged_id(imported_row_id) {
          None => {
            error!(
              "[AppflowyData]: Can't find the new id for the imported row:{}",
              imported_row_id
            );
            None
          },
          Some(new_row_id) => gen_sv_and_doc_state(
            session.user_id,
            new_row_id,
            imported_collab,
            CollabType::DatabaseRow,
          ),
        }
      })
      .collect::<Vec<_>>();

    for gen_collab in gen_collabs {
      write_gen_collab(gen_collab, collab_write_txn);
    }
  }

  Ok(())
}

fn write_collab_object<'a, W>(
  collab: &Collab,
  new_uid: i64,
  new_object_id: &str,
  w_txn: &'a W,
  collab_type: CollabType,
) where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  if let Ok(encode_collab) =
    collab.encode_collab_v1(|collab| collab_type.validate_require_data(collab))
  {
    if let Ok(update) = Update::decode_v1(&encode_collab.doc_state) {
      let doc = Doc::new();
      {
        let mut txn = doc.transact_mut();
        if let Err(e) = txn.apply_update(update) {
          error!(
            "Collab {} failed to apply update: {}",
            collab.object_id(),
            e
          );
          return;
        }
        drop(txn);
      }

      let txn = doc.transact();
      let state_vector = txn.state_vector();
      let doc_state = txn.encode_state_as_update_v1(&StateVector::default());
      if let Err(err) =
        w_txn.flush_doc(new_uid, &new_object_id, state_vector.encode_v1(), doc_state)
      {
        error!(
          "[AppflowyData]:import collab:{} failed: {:?}",
          new_object_id, err
        );
      }
    }
  } else {
    event!(tracing::Level::ERROR, "decode v1 failed");
  }
}

struct GenCollab {
  uid: i64,
  sv: Vec<u8>,
  doc_state: Vec<u8>,
  object_id: String,
}

fn write_gen_collab<'a, W>(collab: GenCollab, w_txn: &'a W)
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  if let Err(err) = w_txn.flush_doc(collab.uid, &collab.object_id, collab.sv, collab.doc_state) {
    error!(
      "[AppflowyData]:import collab:{} failed: {:?}",
      collab.object_id, err
    );
  }
}

fn gen_sv_and_doc_state(
  uid: i64,
  object_id: &str,
  collab: &Collab,
  collab_type: CollabType,
) -> Option<GenCollab> {
  let encoded_collab = collab
    .encode_collab_v1(|collab| collab_type.validate_require_data(collab))
    .ok()?;
  let update = Update::decode_v1(&encoded_collab.doc_state).ok()?;
  let doc = Doc::new();
  let mut txn = doc.transact_mut();
  if let Err(e) = txn.apply_update(update) {
    error!(
      "Collab {} failed to apply update: {}",
      collab.object_id(),
      e
    );
    return None;
  }
  drop(txn);

  let txn = doc.transact();
  let state_vector = txn.state_vector();
  let doc_state = txn.encode_state_as_update_v1(&StateVector::default());
  Some(GenCollab {
    uid,
    sv: state_vector.encode_v1(),
    doc_state,
    object_id: object_id.to_string(),
  })
}

struct MigrateViews {
  child_views: Vec<ParentChildViews>,
  orphan_views: Vec<ParentChildViews>,
  invalid_orphan_views: Vec<ParentChildViews>,
  #[allow(dead_code)]
  not_exist_parent_view_ids: Vec<String>,
}

#[instrument(level = "debug", skip_all, err)]
fn migrate_folder_views<'a, W>(
  root_view_id: &str,
  old_to_new_id_map: &mut OldToNewIdMap,
  imported_session: &Session,
  imported_collab_db_read_txn: &W,
  imported_collab_by_oid: &HashMap<String, Collab>,
) -> Result<MigrateViews, PersistenceError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  let mut imported_folder_collab = Collab::new(
    imported_session.user_id,
    &imported_session.user_workspace.id,
    "migrate_device",
    vec![],
    false,
  );

  imported_collab_db_read_txn
    .load_doc_with_txn(
      imported_session.user_id,
      &imported_session.user_workspace.id,
      &mut imported_folder_collab.transact_mut(),
    )
    .map_err(|err| {
      PersistenceError::Internal(anyhow!(
        "[AppflowyData]: Can't load the user:{} folder:{}. {}",
        imported_session.user_id,
        imported_session.user_workspace.id,
        err
      ))
    })?;
  let other_user_id = UserId::from(imported_session.user_id);
  let imported_folder =
    Folder::open(other_user_id, imported_folder_collab, None).map_err(|err| {
      PersistenceError::Internal(anyhow!("[AppflowyData]:Can't open folder:{}", err))
    })?;

  let mut imported_folder_data = imported_folder
    .get_folder_data(&imported_session.user_workspace.id)
    .ok_or(PersistenceError::Internal(anyhow!(
      "[AppflowyData]: Can't read the folder data"
    )))?;

  let space_views = imported_folder_data
    .workspace
    .child_views
    .iter()
    .map(|view| view.id.clone())
    .collect::<Vec<String>>();

  // Only import views whose collab data is available
  imported_folder_data.views.iter_mut().for_each(|view| {
    view
      .children
      .retain(|view_identifier| imported_collab_by_oid.contains_key(&view_identifier.id));
  });
  let mut not_exist_parent_view_ids = vec![];
  imported_folder_data.views.retain(|view| {
    if space_views.contains(&view.id) {
      if !imported_collab_by_oid.contains_key(&view.id) {
        not_exist_parent_view_ids.push(old_to_new_id_map.exchange_new_id(&view.id));
      }
      true
    } else {
      imported_collab_by_oid.contains_key(&view.id)
    }
  });

  // replace the old parent view id of the workspace
  old_to_new_id_map.0.insert(
    imported_session.user_workspace.id.clone(),
    root_view_id.to_string(),
  );

  let trash_ids = imported_folder_data
    .trash
    .into_values()
    .flatten()
    .map(|item| old_to_new_id_map.exchange_new_id(&item.id))
    .collect::<Vec<String>>();

  // 1. Replace the  views id with new view id
  let mut views_not_in_trash = imported_folder_data
    .workspace
    .child_views
    .items
    .into_iter()
    .filter(|view| !trash_ids.contains(&view.id))
    .collect::<Vec<ViewIdentifier>>();

  views_not_in_trash.iter_mut().for_each(|view_identifier| {
    view_identifier.id = old_to_new_id_map.exchange_new_id(&view_identifier.id);
  });

  let mut all_views = imported_folder_data.views;
  all_views.iter_mut().for_each(|view| {
    // 2. replace the old parent view id of the view
    view.parent_view_id = old_to_new_id_map.exchange_new_id(&view.parent_view_id);

    // 3. replace the old id of the view
    view.id = old_to_new_id_map.exchange_new_id(&view.id);

    // 4. replace the old id of the children views
    view.children.iter_mut().for_each(|view_identifier| {
      view_identifier.id = old_to_new_id_map.exchange_new_id(&view_identifier.id);
    });
  });

  let mut all_views_map = all_views
    .into_iter()
    .filter(|view| !trash_ids.contains(&view.id))
    .map(|view| (view.id.clone(), view))
    .collect::<HashMap<String, View>>();

  // 5. create the parent views. Each parent view contains the children views.
  let parent_views = views_not_in_trash
    .into_iter()
    .flat_map(
      |view_identifier| match all_views_map.remove(&view_identifier.id) {
        None => {
          warn!(
            "[AppflowyData]: Can't find the view:{} in the all views map",
            view_identifier.id
          );
          None
        },
        Some(view) => parent_view_from_view(view, &mut all_views_map),
      },
    )
    .collect::<Vec<ParentChildViews>>();

  // 6. after the parent views are created, the all_views_map only contains the orphan views
  info!(
    "[AppflowyData]: create orphan views: {:?}",
    all_views_map.keys()
  );
  let parent_views = NestedViews {
    views: parent_views,
  };

  let mut orphan_views = vec![];
  let mut invalid_orphan_views = vec![];
  for orphan_view in all_views_map.into_values() {
    if parent_views
      .find_view(&orphan_view.parent_view_id)
      .is_none()
    {
      invalid_orphan_views.push(ParentChildViews {
        view: orphan_view,
        children: vec![],
      });
    } else {
      orphan_views.push(ParentChildViews {
        view: orphan_view,
        children: vec![],
      });
    }
  }

  info!(
    "[AppflowyData]: parent views: {}, orphan views: {}, invalid orphan views: {}, views without collab data: {}",
    parent_views.len(),
    orphan_views.len(),
    invalid_orphan_views.len(),
    not_exist_parent_view_ids.len()
  );

  Ok(MigrateViews {
    child_views: parent_views.views,
    orphan_views,
    invalid_orphan_views,
    not_exist_parent_view_ids,
  })
}

fn parent_view_from_view(
  parent_view: View,
  all_views_map: &mut HashMap<String, View>,
) -> Option<ParentChildViews> {
  let child_views = parent_view
    .children
    .iter()
    .flat_map(
      |view_identifier| match all_views_map.remove(&view_identifier.id) {
        None => None,
        Some(child_view) => parent_view_from_view(child_view, all_views_map),
      },
    )
    .collect::<Vec<ParentChildViews>>();

  Some(ParentChildViews {
    view: parent_view,
    children: child_views,
  })
}

#[derive(Default)]
struct OldToNewIdMap(HashMap<String, String>);

impl OldToNewIdMap {
  fn new() -> Self {
    Self::default()
  }
  fn exchange_new_id(&mut self, old_id: &str) -> String {
    let view_id = self
      .0
      .entry(old_id.to_string())
      .or_insert(gen_view_id().to_string());
    (*view_id).clone()
  }

  fn get_exchanged_id(&self, old_id: &str) -> Option<&String> {
    self.0.get(old_id)
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

#[instrument(level = "debug", skip_all)]
pub async fn upload_collab_objects_data(
  uid: i64,
  user_collab_db: Weak<CollabKVDB>,
  workspace_id: &str,
  user_authenticator: &Authenticator,
  collab_data: ImportedCollabData,
  user_cloud_service: Arc<dyn UserCloudService>,
) -> Result<(), FlowyError> {
  // Only support uploading the collab data when the current server is AppFlowy Cloud server
  if !user_authenticator.is_appflowy_cloud() {
    return Ok(());
  }

  let ImportedCollabData {
    row_object_ids,
    document_object_ids,
    database_object_ids,
  } = collab_data;
  {
    let object_by_collab_type = tokio::task::spawn_blocking(move || {
      let user_collab_db = user_collab_db.upgrade().ok_or_else(|| {
        FlowyError::internal().with_context(
          "The collab db has been dropped, indicating that the user has switched to a new account",
        )
      })?;

      let collab_read = user_collab_db.read_txn();
      let mut object_by_collab_type = HashMap::new();

      event!(
        tracing::Level::DEBUG,
        "[AppflowyData]:upload database collab data"
      );
      object_by_collab_type.insert(
        CollabType::Database,
        load_and_process_collab_data(uid, &collab_read, &database_object_ids),
      );

      event!(
        tracing::Level::DEBUG,
        "[AppflowyData]:upload document collab data"
      );
      object_by_collab_type.insert(
        CollabType::Document,
        load_and_process_collab_data(uid, &collab_read, &document_object_ids),
      );

      event!(
        tracing::Level::DEBUG,
        "[AppflowyData]:upload database row collab data"
      );
      object_by_collab_type.insert(
        CollabType::DatabaseRow,
        load_and_process_collab_data(uid, &collab_read, &row_object_ids),
      );
      Ok::<_, FlowyError>(object_by_collab_type)
    })
    .await??;

    let mut size_counter = 0;
    let mut objects: Vec<UserCollabParams> = vec![];
    for (collab_type, encoded_collab_by_oid) in object_by_collab_type {
      for (oid, encoded_collab) in encoded_collab_by_oid {
        let obj_size = encoded_collab.len();
        // Add the current object to the batch.
        objects.push(UserCollabParams {
          object_id: oid,
          encoded_collab,
          collab_type: collab_type.clone(),
        });
        size_counter += obj_size;
      }
    }

    // Spawn a new task to upload the collab objects data in the background. If the
    // upload fails, we will retry the upload later.
    // af_spawn(async move {
    if !objects.is_empty() {
      batch_create(
        uid,
        workspace_id,
        &user_cloud_service,
        &size_counter,
        objects,
      )
      .await;
    }
    // });
  }

  Ok(())
}

async fn batch_create(
  uid: i64,
  workspace_id: &str,
  user_cloud_service: &Arc<dyn UserCloudService>,
  size_counter: &usize,
  objects: Vec<UserCollabParams>,
) {
  match user_cloud_service
    .batch_create_collab_object(workspace_id, objects)
    .await
  {
    Ok(_) => {
      info!(
        "[AppflowyData]:Batch creating collab objects success, origin payload size: {}",
        size_counter
      );
    },
    Err(err) => {
      error!(
      "[AppflowyData]:Batch creating collab objects fail, origin payload size: {}, workspace_id:{}, uid: {}, error: {:?}",
        size_counter, workspace_id, uid,err
      );
    },
  }
}

#[instrument(level = "debug", skip_all)]
fn load_and_process_collab_data<'a, R>(
  uid: i64,
  collab_read: &R,
  object_ids: &[String],
) -> HashMap<String, Vec<u8>>
where
  R: CollabKVAction<'a>,
  PersistenceError: From<R::Error>,
{
  load_collab_by_object_ids(uid, collab_read, object_ids)
    .0
    .into_iter()
    .filter_map(|(oid, collab)| {
      collab
        .encode_collab_v1(|_| Ok::<(), PersistenceError>(()))
        .ok()?
        .encode_to_bytes()
        .ok()
        .map(|encoded_collab| (oid, encoded_collab))
    })
    .collect()
}
