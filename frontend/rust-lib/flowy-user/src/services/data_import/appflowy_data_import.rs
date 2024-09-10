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
use collab::preclude::{Collab, Doc, ReadTxn, StateVector, Transact, Update};
use collab_database::database::{
  is_database_collab, mut_database_views_with_collab, reset_inline_view_id,
};
use collab_database::rows::{database_row_document_id_from_row_id, mut_row_with_collab, RowId};
use collab_database::workspace_database::WorkspaceDatabaseBody;
use collab_document::document_data::default_document_collab_data;
use collab_entity::CollabType;
use collab_folder::{Folder, UserId, View, ViewIdentifier, ViewLayout};
use collab_integrate::{CollabKVAction, CollabKVDB, PersistenceError};
use collab_plugins::local_storage::kv::KVTransactionDB;

use collab::preclude::updates::encoder::Encode;
use flowy_error::FlowyError;
use flowy_folder_pub::cloud::gen_view_id;
use flowy_folder_pub::entities::{AppFlowyData, ImportData};
use flowy_folder_pub::folder_builder::{ParentChildViews, ViewBuilder};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::cloud::{UserCloudService, UserCollabParams};
use flowy_user_pub::entities::{user_awareness_object_id, Authenticator};
use flowy_user_pub::session::Session;
use std::collections::{HashMap, HashSet};
use std::ops::{Deref, DerefMut};
use std::path::Path;
use std::sync::{Arc, Weak};
use tracing::{debug, error, event, info, instrument, warn};

pub(crate) struct ImportedFolder {
  pub imported_session: Session,
  pub imported_collab_db: Arc<CollabKVDB>,
  pub container_name: Option<String>,
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

pub(crate) fn prepare_import(path: &str) -> anyhow::Result<ImportedFolder> {
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
  let sqlite_db_path = user_paths.sqlite_db_path(imported_session.user_id);
  let imported_sqlite_db = flowy_sqlite::init(sqlite_db_path)
    .map_err(|err| anyhow!("open import collab db failed: {:?}", err))?;
  let imported_collab_db = Arc::new(
    CollabKVDB::open(collab_db_path)
      .map_err(|err| anyhow!("open import collab db failed: {:?}", err))?,
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

pub(crate) fn generate_import_data(
  current_session: &Session,
  workspace_id: &str,
  collab_db: &Arc<CollabKVDB>,
  imported_folder: ImportedFolder,
) -> anyhow::Result<ImportData> {
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

  let views = collab_db.with_write_txn(|collab_write_txn| {
    let imported_collab_read_txn = imported_collab_db.read_txn();
    // use the old_to_new_id_map to keep track of the other collab object id and the new collab object id
    let mut old_to_new_id_map = OldToNewIdMap::new();

    // 1. Get all the imported collab object ids
    let mut all_imported_object_ids = imported_collab_read_txn
      .get_all_docs()
      .map(|iter| iter.collect::<Vec<String>>())
      .unwrap_or_default();

    // when doing import, we don't want to import these objects:
    // 1. user workspace
    // 2. database view tracker
    // 3. the user awareness
    // So we remove these object ids from the list
    let user_workspace_id = &imported_session.user_workspace.id;
    let database_indexer_id = &imported_session.user_workspace.database_indexer_id;
    let user_awareness_id =
      user_awareness_object_id(&imported_session.user_uuid, user_workspace_id).to_string();
    all_imported_object_ids.retain(|id| {
      id != user_workspace_id && id != database_indexer_id && id != &user_awareness_id
    });

    match imported_folder.source {
      ImportedSource::ExternalFolder => {
        // 2. mapping the database indexer ids
        mapping_database_indexer_ids(
          &mut old_to_new_id_map,
          &imported_session,
          &imported_collab_read_txn,
          &mut database_view_ids_by_database_id,
          &mut database_object_ids,
        )?;
      },
      ImportedSource::AnonUser => {
        // 2. migrate the database with views object
        migrate_database_with_views_object(
          &mut old_to_new_id_map,
          &imported_session,
          &imported_collab_read_txn,
          current_session,
          collab_write_txn,
        )?;
      },
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
    let mut imported_collab_by_oid = load_collab_by_object_ids(
      imported_session.user_id,
      &imported_collab_read_txn,
      &all_imported_object_ids,
    );

    // import the database
    migrate_databases(
      &mut old_to_new_id_map,
      current_session,
      collab_write_txn,
      &mut all_imported_object_ids,
      &mut imported_collab_by_oid,
      &mut row_object_ids,
    )?;

    // the object ids now only contains the document collab object ids
    for object_id in &all_imported_object_ids {
      if let Some(imported_collab) = imported_collab_by_oid.get(object_id) {
        let new_object_id = old_to_new_id_map.exchange_new_id(object_id);
        document_object_ids.insert(new_object_id.clone());
        debug!("import from: {}, to: {}", object_id, new_object_id,);
        write_collab_object(
          imported_collab,
          current_session.user_id,
          &new_object_id,
          collab_write_txn,
        );
      }
    }

    // Update the parent view IDs of all top-level views to match the new container view ID, making
    // them child views of the container. This ensures that the hierarchy within the imported
    // structure is correctly maintained.
    let (mut child_views, orphan_views) = mapping_folder_views(
      &import_container_view_id,
      &mut old_to_new_id_map,
      &imported_session,
      &imported_collab_read_txn,
    )?;

    match imported_folder.source {
      ImportedSource::ExternalFolder => match imported_container_view_name {
        None => {
          child_views.extend(orphan_views);
          Ok(child_views)
        },
        Some(container_name) => {
          // create a new view with given name and then attach views to it
          attach_to_new_view(
            current_session,
            &mut document_object_ids,
            &import_container_view_id,
            collab_write_txn,
            child_views,
            orphan_views,
            container_name,
          )
        },
      },
      ImportedSource::AnonUser => {
        child_views.extend(orphan_views);
        Ok(child_views)
      },
    }
  })?;

  Ok(ImportData::AppFlowyDataFolder {
    items: vec![
      AppFlowyData::Folder {
        views,
        database_view_ids_by_database_id,
      },
      AppFlowyData::CollabObject {
        row_object_ids: row_object_ids.into_iter().collect(),
        database_object_ids: database_object_ids.into_iter().collect(),
        document_object_ids: document_object_ids.into_iter().collect(),
      },
    ],
  })
}
fn attach_to_new_view<'a, W>(
  current_session: &Session,
  document_object_ids: &mut HashSet<String>,
  import_container_view_id: &str,
  collab_write_txn: &'a W,
  child_views: Vec<ParentChildViews>,
  orphan_views: Vec<ParentChildViews>,
  container_name: String,
) -> Result<Vec<ParentChildViews>, PersistenceError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
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
  import_collab_object_with_doc_state(
    import_container_doc_state,
    current_session.user_id,
    import_container_view_id,
    collab_write_txn,
  )?;

  document_object_ids.insert(import_container_view_id.to_string());
  let mut import_container_views = vec![ViewBuilder::new(
    current_session.user_id,
    current_session.user_workspace.id.clone(),
  )
  .with_view_id(import_container_view_id)
  .with_layout(ViewLayout::Document)
  .with_name(name)
  .with_child_views(child_views)
  .build()];

  import_container_views.extend(orphan_views);
  Ok(import_container_views)
}

fn mapping_database_indexer_ids<'a, W>(
  old_to_new_id_map: &mut OldToNewIdMap,
  imported_session: &Session,
  imported_collab_read_txn: &W,
  database_view_ids_by_database_id: &mut HashMap<String, Vec<String>>,
  database_object_ids: &mut HashSet<String>,
) -> Result<(), PersistenceError>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  let mut imported_database_indexer = Collab::new(
    imported_session.user_id,
    &imported_session.user_workspace.database_indexer_id,
    "import_device",
    vec![],
    false,
  );
  imported_collab_read_txn.load_doc_with_txn(
    imported_session.user_id,
    &imported_session.user_workspace.database_indexer_id,
    &mut imported_database_indexer.transact_mut(),
  )?;

  let array = WorkspaceDatabaseBody::open(&mut imported_database_indexer);
  for database_meta_list in array.get_all_database_meta(&imported_database_indexer.transact()) {
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

fn migrate_database_with_views_object<'a, 'b, W, R>(
  old_to_new_id_map: &mut OldToNewIdMap,
  old_user_session: &Session,
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
  let mut database_with_views_collab = Collab::new(
    old_user_session.user_id,
    &old_user_session.user_workspace.database_indexer_id,
    "migrate_device",
    vec![],
    false,
  );
  old_collab_r_txn.load_doc_with_txn(
    old_user_session.user_id,
    &old_user_session.user_workspace.database_indexer_id,
    &mut database_with_views_collab.transact_mut(),
  )?;

  let new_uid = new_user_session.user_id;
  let new_object_id = &new_user_session.user_workspace.database_indexer_id;

  let array = WorkspaceDatabaseBody::open(&mut database_with_views_collab);
  let mut txn = database_with_views_collab.transact_mut();
  for database_meta in array.get_all_database_meta(&txn) {
    array.update_database(&mut txn, &database_meta.database_id, |update| {
      let new_linked_views = update
        .linked_views
        .iter()
        .map(|view_id| old_to_new_id_map.exchange_new_id(view_id))
        .collect();
      update.database_id = old_to_new_id_map.exchange_new_id(&update.database_id);
      update.linked_views = new_linked_views;
    })
  }

  if let Err(err) = new_collab_w_txn.create_new_doc(new_uid, new_object_id, &txn) {
    error!("🔴migrate database storage failed: {:?}", err);
  }
  drop(txn);
  Ok(())
}

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
      debug!(
        "migrate database from: {}, to: {}",
        object_id, new_object_id,
      );
      write_collab_object(
        database_collab,
        session.user_id,
        &new_object_id,
        collab_write_txn,
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
    for imported_row_id in imported_row_ids {
      if let Some(imported_collab) = imported_collab_by_oid.get_mut(&imported_row_id) {
        let new_database_id = old_to_new_id_map.exchange_new_id(&database_id);
        let new_row_id = old_to_new_id_map.exchange_new_id(&imported_row_id);
        info!(
          "import database row from: {}, to: {}",
          imported_row_id, new_row_id,
        );

        mut_row_with_collab(imported_collab, |row_update| {
          row_update.set_row_id(RowId::from(new_row_id.clone()), new_database_id.clone());
        });
        write_collab_object(
          imported_collab,
          session.user_id,
          &new_row_id,
          collab_write_txn,
        );
      }

      // imported_collab_by_oid contains all the collab object ids, including the row document collab object ids.
      // So, if the id exist in the imported_collab_by_oid, it means the row document collab object is exist.
      let imported_row_document_id = database_row_document_id_from_row_id(&imported_row_id);
      if imported_collab_by_oid
        .get(&imported_row_document_id)
        .is_some()
      {
        let new_row_document_id = old_to_new_id_map.exchange_new_id(&imported_row_document_id);
        row_document_object_ids.insert(new_row_document_id);
      }
    }
  }

  debug!(
    "import row document ids: {:?}",
    row_document_object_ids.iter().collect::<Vec<&String>>()
  );

  Ok(())
}

fn write_collab_object<'a, W>(collab: &Collab, new_uid: i64, new_object_id: &str, w_txn: &'a W)
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  if let Ok(encode_collab) = collab.encode_collab_v1(|_| Ok::<(), PersistenceError>(())) {
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
      }

      let txn = doc.transact();
      let state_vector = txn.state_vector();
      let doc_state = txn.encode_state_as_update_v1(&StateVector::default());
      info!(
        "import collab:{} with len: {}",
        new_object_id,
        doc_state.len()
      );
      if let Err(err) =
        w_txn.flush_doc(new_uid, &new_object_id, state_vector.encode_v1(), doc_state)
      {
        error!("import collab:{} failed: {:?}", new_object_id, err);
      }
    }
  } else {
    event!(tracing::Level::ERROR, "decode v1 failed");
  }
}

fn import_collab_object_with_doc_state<'a, W>(
  doc_state: Vec<u8>,
  new_uid: i64,
  new_object_id: &str,
  w_txn: &'a W,
) -> Result<(), anyhow::Error>
where
  W: CollabKVAction<'a>,
  PersistenceError: From<W::Error>,
{
  let collab = Collab::new_with_source(
    CollabOrigin::Empty,
    new_object_id,
    DataSource::DocStateV1(doc_state),
    vec![],
    false,
  )?;
  write_collab_object(&collab, new_uid, new_object_id, w_txn);
  Ok(())
}

fn mapping_folder_views<'a, W>(
  root_view_id: &str,
  old_to_new_id_map: &mut OldToNewIdMap,
  imported_session: &Session,
  imported_collab_read_txn: &W,
) -> Result<(Vec<ParentChildViews>, Vec<ParentChildViews>), PersistenceError>
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
  imported_collab_read_txn.load_doc_with_txn(
    imported_session.user_id,
    &imported_session.user_workspace.id,
    &mut imported_folder_collab.transact_mut(),
  )?;
  let other_user_id = UserId::from(imported_session.user_id);
  let imported_folder = Folder::open(other_user_id, imported_folder_collab, None)
    .map_err(|err| PersistenceError::InvalidData(err.to_string()))?;

  let imported_folder_data = imported_folder
    .get_folder_data(&imported_session.user_workspace.id)
    .ok_or(PersistenceError::Internal(anyhow!(
      "Can't read the folder data"
    )))?;

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
  let mut first_level_views = imported_folder_data
    .workspace
    .child_views
    .items
    .into_iter()
    .filter(|view| !trash_ids.contains(&view.id))
    .collect::<Vec<ViewIdentifier>>();

  first_level_views.iter_mut().for_each(|view_identifier| {
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
  let parent_views = first_level_views
    .into_iter()
    .flat_map(
      |view_identifier| match all_views_map.remove(&view_identifier.id) {
        None => None,
        Some(view) => parent_view_from_view(view, &mut all_views_map),
      },
    )
    .collect::<Vec<ParentChildViews>>();

  // 6. after the parent views are created, the all_views_map only contains the orphan views
  debug!("create orphan views: {:?}", all_views_map.keys());
  let mut orphan_views = vec![];
  for orphan_view in all_views_map.into_values() {
    orphan_views.push(ParentChildViews {
      parent_view: orphan_view,
      child_views: vec![],
    });
  }

  Ok((parent_views, orphan_views))
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
    parent_view,
    child_views,
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
  appflowy_data: AppFlowyData,
  user_cloud_service: Arc<dyn UserCloudService>,
) -> Result<(), FlowyError> {
  // Only support uploading the collab data when the current server is AppFlowy Cloud server
  if !user_authenticator.is_appflowy_cloud() {
    return Ok(());
  }

  match appflowy_data {
    AppFlowyData::Folder { .. } => {},
    AppFlowyData::CollabObject {
      row_object_ids,
      document_object_ids,
      database_object_ids,
    } => {
      let object_by_collab_type = tokio::task::spawn_blocking(move || {
       let user_collab_db = user_collab_db.upgrade().ok_or_else(|| {
          FlowyError::internal().with_context("The collab db has been dropped, indicating that the user has switched to a new account")
        })?;

        let collab_read = user_collab_db.read_txn();
        let mut object_by_collab_type = HashMap::new();

        event!(tracing::Level::DEBUG, "upload database collab data");
        object_by_collab_type.insert(
          CollabType::Database,
          load_and_process_collab_data(uid, &collab_read, &database_object_ids),
        );

        event!(tracing::Level::DEBUG, "upload document collab data");
        object_by_collab_type.insert(
          CollabType::Document,
          load_and_process_collab_data(uid, &collab_read, &document_object_ids),
        );

        event!(tracing::Level::DEBUG, "upload database row collab data");
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
    },
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
  let ids = objects
    .iter()
    .map(|o| o.object_id.clone())
    .collect::<Vec<_>>()
    .join(", ");
  match user_cloud_service
    .batch_create_collab_object(workspace_id, objects)
    .await
  {
    Ok(_) => {
      info!(
        "Batch creating collab objects success, origin payload size: {}",
        size_counter
      );
    },
    Err(err) => {
      error!(
      "Batch creating collab objects fail:{}, origin payload size: {}, workspace_id:{}, uid: {}, error: {:?}",
       ids, size_counter, workspace_id, uid,err
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
