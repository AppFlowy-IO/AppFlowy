use crate::services::persistence::DatabaseDBConnection;
use diesel::{ExpressionMethods, QueryDsl, RunQueryDsl};
use flowy_error::FlowyResult;
use flowy_sqlite::{
  prelude::*,
  schema::{database_refs, database_refs::dsl},
};
use std::sync::Arc;

pub struct DatabaseRefs {
  database: Arc<dyn DatabaseDBConnection>,
}

impl DatabaseRefs {
  pub fn new(database: Arc<dyn DatabaseDBConnection>) -> Self {
    Self { database }
  }

  pub fn bind(
    &self,
    database_id: &str,
    view_id: &str,
    is_base: bool,
    name: &str,
  ) -> FlowyResult<()> {
    let conn = self.database.get_db_connection()?;
    let ref_id = make_ref_id(database_id, view_id);
    let record = DatabaseRefRecord {
      ref_id,
      name: name.to_string(),
      is_base,
      view_id: view_id.to_string(),
      database_id: database_id.to_string(),
    };
    let _ = diesel::replace_into(database_refs::table)
      .values(record)
      .execute(&*conn)?;
    Ok(())
  }

  pub fn unbind(&self, view_id: &str) -> FlowyResult<()> {
    let conn = self.database.get_db_connection()?;
    diesel::delete(dsl::database_refs.filter(database_refs::view_id.eq(view_id)))
      .execute(&*conn)?;
    Ok(())
  }

  pub fn get_ref_views_with_database(
    &self,
    database_id: &str,
  ) -> FlowyResult<Vec<DatabaseViewRef>> {
    let conn = self.database.get_db_connection()?;
    let views = dsl::database_refs
      .filter(database_refs::database_id.like(database_id))
      .load::<DatabaseRefRecord>(&*conn)?
      .into_iter()
      .map(|record| record.into())
      .collect::<Vec<_>>();
    tracing::trace!("database:{} has {} ref views", database_id, views.len());
    Ok(views)
  }

  pub fn get_database_with_view(&self, view_id: &str) -> FlowyResult<DatabaseInfo> {
    let conn = self.database.get_db_connection()?;
    let record = dsl::database_refs
      .filter(database_refs::view_id.eq(view_id))
      .first::<DatabaseRefRecord>(&*conn)?;
    Ok(record.into())
  }

  pub fn get_all_databases(&self) -> FlowyResult<Vec<DatabaseInfo>> {
    let conn = self.database.get_db_connection()?;
    let database_infos = dsl::database_refs
      .filter(database_refs::is_base.eq(true))
      .load::<DatabaseRefRecord>(&*conn)?
      .into_iter()
      .map(|record| record.into())
      .collect::<Vec<DatabaseInfo>>();

    Ok(database_infos)
  }
}

fn make_ref_id(database_id: &str, view_id: &str) -> String {
  format!("{}:{}", database_id, view_id)
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "database_refs"]
#[primary_key(ref_id)]
struct DatabaseRefRecord {
  ref_id: String,
  name: String,
  is_base: bool,
  view_id: String,
  database_id: String,
}

pub struct DatabaseViewRef {
  pub view_id: String,
  pub name: String,
  pub database_id: String,
}
impl std::convert::From<DatabaseRefRecord> for DatabaseViewRef {
  fn from(record: DatabaseRefRecord) -> Self {
    Self {
      view_id: record.view_id,
      name: record.name,
      database_id: record.database_id,
    }
  }
}

pub struct DatabaseInfo {
  pub name: String,
  pub database_id: String,
}

impl std::convert::From<DatabaseRefRecord> for DatabaseInfo {
  fn from(record: DatabaseRefRecord) -> Self {
    Self {
      name: record.name,
      database_id: record.database_id,
    }
  }
}
