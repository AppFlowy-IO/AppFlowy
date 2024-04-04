use std::sync::Arc;

use chrono::NaiveDateTime;
use diesel::{RunQueryDsl, SqliteConnection};
use semver::Version;

use collab_integrate::CollabKVDB;
use flowy_error::FlowyResult;
use flowy_sqlite::schema::user_data_migration_records;
use flowy_sqlite::ConnectionPool;
use flowy_user_pub::entities::Authenticator;

use flowy_user_pub::session::Session;

pub struct UserLocalDataMigration {
  session: Session,
  collab_db: Arc<CollabKVDB>,
  sqlite_pool: Arc<ConnectionPool>,
}

impl UserLocalDataMigration {
  pub fn new(
    session: Session,
    collab_db: Arc<CollabKVDB>,
    sqlite_pool: Arc<ConnectionPool>,
  ) -> Self {
    Self {
      session,
      collab_db,
      sqlite_pool,
    }
  }

  /// Executes a series of migrations.
  ///
  /// This function applies each migration in the `migrations` vector that hasn't already been executed.
  /// It retrieves the current migration records from the database, and for each migration in the `migrations` vector,
  /// checks whether it has already been run. If it hasn't, the function runs the migration and adds it to the list of applied migrations.
  ///
  /// The function does not apply a migration if its name is already in the list of applied migrations.
  /// If a migration name is duplicated, the function logs an error message and continues with the next migration.
  ///
  /// # Arguments
  ///
  /// * `migrations` - A vector of boxed dynamic `UserDataMigration` objects representing the migrations to be applied.
  ///
  pub fn run(
    self,
    migrations: Vec<Box<dyn UserDataMigration>>,
    authenticator: &Authenticator,
    app_version: Option<Version>,
  ) -> FlowyResult<Vec<String>> {
    let mut applied_migrations = vec![];
    let mut conn = self.sqlite_pool.get()?;
    let record = get_all_records(&mut conn)?;
    let mut duplicated_names = vec![];
    for migration in migrations {
      if !record
        .iter()
        .any(|record| record.migration_name == migration.name())
      {
        if let Some(app_version) = app_version.as_ref() {
          if !migration.applies_to_version(app_version) {
            continue;
          }
        }

        let migration_name = migration.name().to_string();
        if !duplicated_names.contains(&migration_name) {
          migration.run(&self.session, &self.collab_db, authenticator)?;
          applied_migrations.push(migration.name().to_string());
          save_migration_record(&mut conn, &migration_name);
          duplicated_names.push(migration_name);
        } else {
          tracing::error!("Duplicated migration name: {}", migration_name);
        }
      }
    }
    Ok(applied_migrations)
  }
}

pub trait UserDataMigration {
  /// Migration with the same name will be skipped
  fn name(&self) -> &str;
  /// Returns bool value whether the migration should be applied to the current app version
  /// true if the migration should be applied, false otherwise
  fn applies_to_version(&self, app_version: &Version) -> bool;
  fn run(
    &self,
    user: &Session,
    collab_db: &Arc<CollabKVDB>,
    authenticator: &Authenticator,
  ) -> FlowyResult<()>;
}

pub(crate) fn save_migration_record(conn: &mut SqliteConnection, migration_name: &str) {
  let new_record = NewUserDataMigrationRecord {
    migration_name: migration_name.to_string(),
  };
  diesel::insert_into(user_data_migration_records::table)
    .values(&new_record)
    .execute(conn)
    .expect("Error inserting new migration record");
}

fn get_all_records(conn: &mut SqliteConnection) -> FlowyResult<Vec<UserDataMigrationRecord>> {
  Ok(
    user_data_migration_records::table
      .load::<UserDataMigrationRecord>(conn)
      .unwrap_or_default(),
  )
}

#[derive(Clone, Default, Queryable, Identifiable)]
#[diesel(table_name = user_data_migration_records)]
pub struct UserDataMigrationRecord {
  pub id: i32,
  pub migration_name: String,
  pub executed_at: NaiveDateTime,
}

#[derive(Insertable)]
#[diesel(table_name = user_data_migration_records)]
pub struct NewUserDataMigrationRecord {
  pub migration_name: String,
}
