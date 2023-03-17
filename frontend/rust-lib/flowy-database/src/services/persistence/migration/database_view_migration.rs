use crate::services::database_view::make_database_view_rev_manager;
use crate::services::persistence::database_ref::DatabaseRefs;
use flowy_error::FlowyResult;
use flowy_sqlite::kv::KV;

use crate::services::persistence::migration::MigratedDatabase;
use crate::services::persistence::rev_sqlite::SQLiteDatabaseViewRevisionPersistence;
use bytes::Bytes;
use database_model::DatabaseViewRevision;
use flowy_client_sync::client_database::{
  make_database_view_operations, make_database_view_rev_json_str, DatabaseViewOperationsBuilder,
  DatabaseViewRevisionPad,
};
use flowy_revision::reset::{RevisionResettable, RevisionStructReset};
use flowy_sqlite::{
  prelude::*,
  schema::{grid_view_rev_table, grid_view_rev_table::dsl},
};
use lib_infra::util::md5;
use revision_model::Revision;
use std::sync::Arc;

const DATABASE_VIEW_MIGRATE: &str = "database_view_migrate";

pub fn is_database_view_migrated(user_id: &str) -> bool {
  let key = md5(format!("{}{}", user_id, DATABASE_VIEW_MIGRATE));
  KV::get_bool(&key)
}

pub(crate) async fn migrate_database_view(
  user_id: &str,
  database_refs: Arc<DatabaseRefs>,
  migrated_databases: &Vec<MigratedDatabase>,
  pool: Arc<ConnectionPool>,
) -> FlowyResult<()> {
  if is_database_view_migrated(user_id) || migrated_databases.is_empty() {
    return Ok(());
  }

  let mut database_with_view = vec![];

  let database_without_view = {
    let conn = pool.get()?;
    let databases = migrated_databases
      .iter()
      .filter(|database| {
        let predicate = grid_view_rev_table::object_id.eq(&database.view_id);
        let exist = diesel::dsl::exists(dsl::grid_view_rev_table.filter(predicate));
        match select(exist).get_result::<bool>(&*conn) {
          Ok(is_exist) => {
            if is_exist {
              database_with_view.push((**database).clone())
            }
            !is_exist
          },
          Err(_) => true,
        }
      })
      .collect::<Vec<&MigratedDatabase>>();
    drop(conn);
    databases
  };

  // Create database view if it's not exist.
  for database in database_without_view {
    tracing::debug!("[Migration]: create database view: {}", database.view_id);
    let database_id = database.view_id.clone();
    let database_view_id = database.view_id.clone();
    //
    let database_view_rev = DatabaseViewRevision::new(
      database_id,
      database_view_id.clone(),
      true,
      database.name.clone(),
      database.layout.clone(),
    );
    let database_view_ops = make_database_view_operations(&database_view_rev);
    let database_view_bytes = database_view_ops.json_bytes();
    let revision = Revision::initial_revision(&database_view_id, database_view_bytes);
    let rev_manager =
      make_database_view_rev_manager(user_id, pool.clone(), &database_view_id).await?;
    rev_manager.reset_object(vec![revision]).await?;
  }

  // Reset existing database view
  for database in database_with_view {
    let object = DatabaseViewRevisionResettable {
      database_view_id: database.view_id.clone(),
    };
    let disk_cache = SQLiteDatabaseViewRevisionPersistence::new(user_id, pool.clone());
    let reset = RevisionStructReset::new(user_id, object, Arc::new(disk_cache));
    reset.run().await?;
  }

  tracing::debug!("[Migration]: Add database view refs");
  for database in migrated_databases {
    // Bind the database with database view id. For historical reasons,
    // the default database_id is empty, so the view_id will be used
    // as the database_id.
    let database_id = database.view_id.clone();
    let database_view_id = database.view_id.clone();
    tracing::debug!(
      "Bind database:{} with view:{}",
      database_id,
      database_view_id
    );
    let _ = database_refs.bind(&database_id, &database_view_id, true, &database.name);
  }

  let key = md5(format!("{}{}", user_id, DATABASE_VIEW_MIGRATE));
  KV::set_bool(&key, true);
  Ok(())
}

struct DatabaseViewRevisionResettable {
  database_view_id: String,
}

impl RevisionResettable for DatabaseViewRevisionResettable {
  fn target_id(&self) -> &str {
    &self.database_view_id
  }

  fn reset_data(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
    let pad = DatabaseViewRevisionPad::from_revisions(revisions)?;
    let json = pad.json_str()?;
    let bytes = DatabaseViewOperationsBuilder::new()
      .insert(&json)
      .build()
      .json_bytes();
    Ok(bytes)
  }

  fn default_target_rev_str(&self) -> FlowyResult<String> {
    let database_view_rev = DatabaseViewRevision::default();
    let json = make_database_view_rev_json_str(&database_view_rev)?;
    Ok(json)
  }

  fn read_record(&self) -> Option<String> {
    KV::get_str(self.target_id())
  }

  fn set_record(&self, record: String) {
    KV::set_str(self.target_id(), record);
  }
}
