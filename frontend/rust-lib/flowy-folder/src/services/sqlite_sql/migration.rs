// use flowy_error::FlowyError;
// use flowy_sqlite::{
//   query_dsl::DatabaseConnection, schema::user_data_migration_records, DBConnection,
//   ExpressionMethods, RunQueryDsl,
// };
// use tracing::{error, info};

// pub async fn run_migrations(dir: &str, conn: DBConnection) -> Result<(), FlowyError> {
//   let mut migrations = MigrationList::new();
//   migrations.add_migration(Migration {
//     name: "create_folder_table".to_string(),
//     sql: format!(
//       "CREATE TABLE IF NOT EXISTS folder (
//         view_id TEXT PRIMARY KEY,
//         workspace_id TEXT NOT NULL,
//         name TEXT NOT NULL,
//         icon TEXT,
//         is_space BOOLEAN NOT NULL DEFAULT 0,
//         is_private BOOLEAN NOT NULL DEFAULT 0,
//         is_published BOOLEAN NOT NULL DEFAULT 0,
//         layout INTEGER NOT NULL DEFAULT 0,
//         created_at TEXT NOT NULL,
//         last_edited_time TEXT NOT NULL,
//         is_locked BOOLEAN,
//         parent_id TEXT,
//         sync_status TEXT NOT NULL,
//         last_modified_time TEXT NOT NULL,
//         operation INTEGER NOT NULL
//       );"
//     ),
//   });

//   migrations.run(dir, conn).await
// }

// struct MigrationList {
//   migrations: Vec<Migration>,
// }

// struct Migration {
//   name: String,
//   sql: String,
// }

// impl MigrationList {
//   fn new() -> Self {
//     Self { migrations: vec![] }
//   }

//   fn add_migration(&mut self, migration: Migration) {
//     self.migrations.push(migration);
//   }

//   async fn run(&self, dir: &str, mut conn: DBConnection) -> Result<(), FlowyError> {
//     // Create migration table if it doesn't exist
//     let sql = "CREATE TABLE IF NOT EXISTS user_data_migration_records (
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               migration_name TEXT NOT NULL,
//               executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
//           );";
//     match conn.immediate_transaction::<_, FlowyError, _>(|conn| {
//       let _ = diesel::sql_query(sql).execute(conn)?;
//       Ok(())
//     }) {
//       Ok(_) => {},
//       Err(e) => {
//         error!("Failed to create migration table: {:?}", e);
//         return Err(e);
//       },
//     }

//     for migration in &self.migrations {
//       // Check if migration has already been run
//       let exists = conn
//         .immediate_transaction::<_, FlowyError, _>(|conn| {
//           let count = user_data_migration_records::dsl::user_data_migration_records
//             .filter(user_data_migration_records::migration_name.eq(&migration.name))
//             .count()
//             .get_result::<i64>(conn)?;
//           Ok(count > 0)
//         })
//         .unwrap_or(false);

//       if exists {
//         info!("Migration {} already executed, skipping", migration.name);
//         continue;
//       }

//       // Execute migration
//       conn
//         .immediate_transaction::<_, FlowyError, _>(|conn| {
//           diesel::sql_query(&migration.sql).execute(conn)?;

//           // Record migration
//           diesel::sql_query("INSERT INTO user_data_migration_records (migration_name) VALUES (?)")
//             .bind::<diesel::sql_types::Text, _>(&migration.name)
//             .execute(conn)?;

//           info!("Successfully executed migration: {}", migration.name);
//           Ok(())
//         })
//         .map_err(|e| {
//           error!("Failed to execute migration {}: {:?}", migration.name, e);
//           e
//         })?;
//     }

//     Ok(())
//   }
// }
