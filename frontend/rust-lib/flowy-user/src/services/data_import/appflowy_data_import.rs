use crate::migrations::session_migration::migrate_session_with_user_uuid;

use crate::services::data_import::importer::load_collab_by_oid;
use crate::services::db::UserDBPath;
use crate::services::entities::{Session, UserPaths};
use crate::services::user_awareness::awareness_oid_from_user_uuid;
use anyhow::anyhow;
use collab::core::collab::{CollabDocState, MutexCollab};
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_database::database::{
  is_database_collab, mut_database_views_with_collab, reset_inline_view_id,
};
use collab_database::rows::{database_row_document_id_from_row_id, mut_row_with_collab, RowId};
use collab_database::user::DatabaseViewTrackerList;
use collab_document::document_data::default_document_collab_data;
use collab_folder::{Folder, UserId, View, ViewIdentifier, ViewLayout};
use collab_integrate::{PersistenceError, RocksCollabDB, YrsDocAction};
use flowy_folder_deps::cloud::gen_view_id;
use flowy_folder_deps::entities::ImportData;
use flowy_folder_deps::folder_builder::{ParentChildViews, ViewBuilder};
use flowy_sqlite::kv::StorePreferences;
use parking_lot::{Mutex, RwLock};
use std::collections::{HashMap, HashSet};
use std::ops::{Deref, DerefMut};
use std::sync::Arc;

/// This path refers to the directory where AppFlowy stores its data. The directory structure is as follows:
/// root folder:
///   - cache.db
///   - log (log files with unique identifiers)
///   - 2761499 (other relevant files or directories, identified by unique numbers)

pub(crate) fn import_appflowy_data_folder(
  session: &Session,
  path: String,
  container_name: String,
  collab_db: &Arc<RocksCollabDB>,
) -> anyhow::Result<ImportData> {
  let user_paths = UserPaths::new(path.clone());
  let other_store_preferences = Arc::new(StorePreferences::new(&path)?);
  migrate_session_with_user_uuid("appflowy_session_cache", &other_store_preferences);
  let other_session = other_store_preferences
    .get_object::<Session>("appflowy_session_cache")
    .ok_or(anyhow!(
      "Can't find the session cache in the appflowy data folder at path: {}",
      path
    ))?;

  let other_collab_db = Arc::new(RocksCollabDB::open(
    user_paths.collab_db_path(other_session.user_id),
  )?);
  let other_collab_read_txn = other_collab_db.read_txn();
  let mut database_view_ids_by_database_id: HashMap<String, Vec<String>> = HashMap::new();
  let row_object_ids = Mutex::new(HashSet::new());
  let document_object_ids = Mutex::new(HashSet::new());
  let database_object_ids = Mutex::new(HashSet::new());
  let import_container_view_id = gen_view_id().to_string();

  let view = collab_db.with_write_txn(|collab_write_txn| {
    // use the old_to_new_id_map to keep track of the other collab object id and the new collab object id
    let old_to_new_id_map = Arc::new(Mutex::new(OldToNewIdMap::new()));
    let mut all_object_ids = other_collab_read_txn
      .get_all_docs()
      .map(|iter| iter.collect::<Vec<String>>())
      .unwrap_or_default();

    // when doing import, we don't want to import the user workspace, database view tracker and the user awareness
    all_object_ids.retain(|id| id != &other_session.user_workspace.id);
    all_object_ids.retain(|id| id != &other_session.user_workspace.database_view_tracker_id);
    all_object_ids
      .retain(|id| id != &awareness_oid_from_user_uuid(&other_session.user_uuid).to_string());

    // import database view tracker
    migrate_database_view_tracker(
      &mut old_to_new_id_map.lock(),
      &other_session,
      &other_collab_read_txn,
      &mut database_view_ids_by_database_id,
      &database_object_ids,
    )?;

    // remove the database view ids from the object ids. Because there are no collab object for the database view
    let database_view_ids: Vec<String> = database_view_ids_by_database_id
      .values()
      .flatten()
      .cloned()
      .collect();
    all_object_ids.retain(|id| !database_view_ids.contains(id));

    // load other collab objects
    let collab_by_oid = load_collab_by_oid(
      other_session.user_id,
      &other_collab_read_txn,
      &all_object_ids,
    );
    // import the database
    migrate_databases(
      &old_to_new_id_map,
      session,
      collab_write_txn,
      &mut all_object_ids,
      &collab_by_oid,
      &row_object_ids,
      &document_object_ids,
    )?;

    // the object ids now only contains the document collab object ids
    for object_id in &all_object_ids {
      if let Some(collab) = collab_by_oid.get(object_id) {
        let new_object_id = old_to_new_id_map.lock().renew_id(object_id);
        document_object_ids.lock().insert(new_object_id.clone());
        tracing::debug!("migrate from: {}, to: {}", object_id, new_object_id,);
        import_collab_object(collab, session.user_id, &new_object_id, collab_write_txn);
      }
    }

    // create a root view that contains all the views
    let child_views = import_workspace_views(
      &import_container_view_id,
      &mut old_to_new_id_map.lock(),
      &other_session,
      &other_collab_read_txn,
    )?;

    let name = if container_name.is_empty() {
      format!(
        "import_{}",
        chrono::Local::now().format("%Y-%m-%d %H:%M:%S")
      )
    } else {
      container_name
    };

    // create the content for the container view
    let import_container_doc_state = default_document_collab_data(&import_container_view_id)
      .doc_state
      .to_vec();
    import_collab_object_with_doc_state(
      import_container_doc_state,
      session.user_id,
      &import_container_view_id,
      collab_write_txn,
    )?;

    let import_container_view =
      ViewBuilder::new(session.user_id, session.user_workspace.id.clone())
        .with_view_id(import_container_view_id)
        .with_layout(ViewLayout::Document)
        .with_name(name)
        .with_child_views(child_views)
        .build();

    Ok(import_container_view)
  })?;
  Ok(ImportData::AppFlowyDataFolder {
    view,
    database_view_ids_by_database_id,
    row_object_ids: row_object_ids.into_inner().into_iter().collect(),
    database_object_ids: database_object_ids.into_inner().into_iter().collect(),
    document_object_ids: document_object_ids.into_inner().into_iter().collect(),
  })
}

fn migrate_database_view_tracker<'a, W>(
  old_to_new_id_map: &mut OldToNewIdMap,
  other_session: &Session,
  other_collab_read_txn: &'a W,
  database_view_ids_by_database_id: &mut HashMap<String, Vec<String>>,
  database_object_ids: &Mutex<HashSet<String>>,
) -> Result<(), PersistenceError>
where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let database_view_tracker_collab = Collab::new(
    other_session.user_id,
    &other_session.user_workspace.database_view_tracker_id,
    "phantom",
    vec![],
  );
  database_view_tracker_collab.with_origin_transact_mut(|txn| {
    other_collab_read_txn.load_doc_with_txn(
      other_session.user_id,
      &other_session.user_workspace.database_view_tracker_id,
      txn,
    )
  })?;

  let array = DatabaseViewTrackerList::from_collab(&database_view_tracker_collab);
  for database_view_tracker in array.get_all_database_tracker() {
    database_view_ids_by_database_id.insert(
      old_to_new_id_map.renew_id(&database_view_tracker.database_id),
      database_view_tracker
        .linked_views
        .into_iter()
        .map(|view_id| old_to_new_id_map.renew_id(&view_id))
        .collect(),
    );
  }
  database_object_ids.lock().extend(
    database_view_ids_by_database_id
      .keys()
      .cloned()
      .collect::<Vec<String>>(),
  );
  Ok(())
}

fn migrate_databases<'a, W>(
  old_to_new_id_map: &Arc<Mutex<OldToNewIdMap>>,
  session: &Session,
  collab_write_txn: &'a W,
  object_ids: &mut Vec<String>,
  collab_by_oid: &HashMap<String, Collab>,
  row_object_ids: &Mutex<HashSet<String>>,
  document_object_ids: &Mutex<HashSet<String>>,
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
        old_to_new_id_map.lock().renew_id(&old_inline_view_id)
      });

      mut_database_views_with_collab(collab, |database_view| {
        let new_view_id = old_to_new_id_map.lock().renew_id(&database_view.id);
        let new_database_id = old_to_new_id_map
          .lock()
          .renew_id(&database_view.database_id);

        database_view.id = new_view_id;
        database_view.database_id = new_database_id;
        database_view.row_orders.iter_mut().for_each(|row_order| {
          let old_row_id = String::from(row_order.id.clone());
          let old_row_document_id = database_row_document_id_from_row_id(&old_row_id);
          let new_row_id = old_to_new_id_map.lock().renew_id(&old_row_id);
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

        // collect the ids
        let row_ids = database_view
          .row_orders
          .iter()
          .map(|order| order.id.clone().into_inner())
          .collect::<Vec<String>>();

        let row_document_ids = row_ids
          .iter()
          .map(|id| database_row_document_id_from_row_id(id))
          .collect::<Vec<String>>();

        row_object_ids.lock().extend(row_ids);
        document_object_ids.lock().extend(row_document_ids);
      });

      let new_object_id = old_to_new_id_map.lock().renew_id(object_id);
      tracing::debug!(
        "migrate database from: {}, to: {}",
        object_id,
        new_object_id,
      );
      import_collab_object(collab, session.user_id, &new_object_id, collab_write_txn);
    }
  }
  let database_row_object_ids = database_row_object_ids.read();

  // remove the database object ids from the object ids
  object_ids.retain(|id| !database_object_ids.contains(id));
  object_ids.retain(|id| !database_row_object_ids.contains(id));

  for object_id in &*database_row_object_ids {
    if let Some(collab) = collab_by_oid.get(object_id) {
      let new_object_id = old_to_new_id_map.lock().renew_id(object_id);
      tracing::info!(
        "migrate database row from: {}, to: {}",
        object_id,
        new_object_id,
      );
      mut_row_with_collab(collab, |row_update| {
        row_update.set_row_id(RowId::from(new_object_id.clone()));
      });
      import_collab_object(collab, session.user_id, &new_object_id, collab_write_txn);
    }
  }
  Ok(())
}

fn import_collab_object<'a, W>(collab: &Collab, new_uid: i64, new_object_id: &str, w_txn: &'a W)
where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let txn = collab.transact();
  if let Err(err) = w_txn.create_new_doc(new_uid, &new_object_id, &txn) {
    tracing::error!("import collab failed: {:?}", err);
  }
}

fn import_collab_object_with_doc_state<'a, W>(
  doc_state: CollabDocState,
  new_uid: i64,
  new_object_id: &str,
  w_txn: &'a W,
) -> Result<(), anyhow::Error>
where
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let collab = Collab::new_with_raw_data(CollabOrigin::Empty, new_object_id, doc_state, vec![])?;
  import_collab_object(&collab, new_uid, new_object_id, w_txn);
  Ok(())
}

fn import_workspace_views<'a, 'b, W>(
  parent_view_id: &str,
  old_to_new_id_map: &mut OldToNewIdMap,
  other_session: &Session,
  other_collab_read_txn: &W,
) -> Result<Vec<ParentChildViews>, PersistenceError>
where
  'a: 'b,
  W: YrsDocAction<'a>,
  PersistenceError: From<W::Error>,
{
  let other_folder_collab = Collab::new(
    other_session.user_id,
    &other_session.user_workspace.id,
    "phantom",
    vec![],
  );
  other_folder_collab.with_origin_transact_mut(|txn| {
    other_collab_read_txn.load_doc_with_txn(
      other_session.user_id,
      &other_session.user_workspace.id,
      txn,
    )
  })?;
  let other_user_id = UserId::from(other_session.user_id);
  let other_folder = Folder::open(
    other_user_id,
    Arc::new(MutexCollab::from_collab(other_folder_collab)),
    None,
  )
  .map_err(|err| PersistenceError::InvalidData(err.to_string()))?;
  let other_folder_data = other_folder
    .get_folder_data()
    .ok_or(PersistenceError::Internal(anyhow!(
      "Can't read the folder data"
    )))?;

  // replace the old parent view id of the workspace
  old_to_new_id_map.0.insert(
    other_session.user_workspace.id.clone(),
    parent_view_id.to_string(),
  );
  let trash_ids = other_folder_data
    .trash
    .into_values()
    .flatten()
    .map(|item| old_to_new_id_map.renew_id(&item.id))
    .collect::<Vec<String>>();

  // 1. Replace the workspace views id to new id
  let mut first_level_views = other_folder_data
    .workspace
    .child_views
    .items
    .into_iter()
    .filter(|view| !trash_ids.contains(&view.id))
    .collect::<Vec<ViewIdentifier>>();

  first_level_views.iter_mut().for_each(|view_identifier| {
    view_identifier.id = old_to_new_id_map.renew_id(&view_identifier.id);
  });

  let mut all_views = other_folder_data.views;
  all_views.iter_mut().for_each(|view| {
    // 2. replace the old parent view id of the view
    view.parent_view_id = old_to_new_id_map.renew_id(&view.parent_view_id);

    // 3. replace the old id of the view
    view.id = old_to_new_id_map.renew_id(&view.id);

    // 4. replace the old id of the children views
    view.children.iter_mut().for_each(|view_identifier| {
      view_identifier.id = old_to_new_id_map.renew_id(&view_identifier.id);
    });
  });

  let mut all_views_map = all_views
    .into_iter()
    .filter(|view| !trash_ids.contains(&view.id))
    .map(|view| (view.id.clone(), view))
    .collect::<HashMap<String, View>>();

  let parent_views = first_level_views
    .into_iter()
    .flat_map(
      |view_identifier| match all_views_map.remove(&view_identifier.id) {
        None => None,
        Some(view) => parent_view_from_view(view, &mut all_views_map),
      },
    )
    .collect::<Vec<ParentChildViews>>();

  Ok(parent_views)
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
  fn renew_id(&mut self, old_id: &str) -> String {
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
