use std::sync::Arc;

use tokio_postgres::types::ToSql;
use tokio_postgres::{Client, NoTls};

pub type PostgresClient = Client;
const AF_MIGRATION_HISTORY: &str = "af_migration_history";
pub struct PostgresDB {
  pub configuration: PostgresConfiguration,
  pub client: Arc<PostgresClient>,
}

mod embedded {
  use refinery::embed_migrations;

  embed_migrations!("./src/supabase/migrations");
}

impl PostgresDB {
  pub async fn from_env() -> Result<Self, anyhow::Error> {
    let configuration = PostgresConfiguration::from_env()
      .ok_or_else(|| anyhow::anyhow!("PostgresConfiguration not found in env"))?;
    Self::new(configuration).await
  }

  pub async fn new(configuration: PostgresConfiguration) -> Result<Self, anyhow::Error> {
    let mut config = tokio_postgres::Config::new();
    config
      .host(&configuration.url)
      .user(&configuration.user_name)
      .password(&configuration.password)
      .port(configuration.port);

    // Using the https://docs.rs/postgres-openssl/latest/postgres_openssl/ to enable tls connection.
    let (mut client, connection) = config.connect(NoTls).await?;
    tokio::spawn(async move {
      if let Err(e) = connection.await {
        tracing::error!("postgres db connection error: {}", e);
      }
    });

    match embedded::migrations::runner()
      .set_migration_table_name(AF_MIGRATION_HISTORY)
      .run_async(&mut client)
      .await
    {
      Ok(report) => {
        tracing::trace!("postgres db migration success: {:?}", report);
      },
      Err(e) => {
        tracing::error!("postgres db migration error: {}", e);
        return Err(anyhow::anyhow!("postgres db migration error: {}", e));
      },
    }

    Ok(Self {
      configuration,
      client: Arc::new(client),
    })
  }
}

pub struct UpdateSqlBuilder {
  table: String,
  sets: Vec<(String, Box<dyn ToSql + Sync + Send>)>,
  where_clause: Option<(String, Box<dyn ToSql + Sync + Send>)>,
}

impl UpdateSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      sets: Vec::new(),
      where_clause: None,
    }
  }

  pub fn set<T: 'static + ToSql + Sync + Send>(mut self, column: &str, value: Option<T>) -> Self {
    if let Some(value) = value {
      self.sets.push((column.to_string(), Box::new(value)));
    }
    self
  }

  pub fn where_clause<T: 'static + ToSql + Sync + Send>(mut self, clause: &str, value: T) -> Self {
    self.where_clause = Some((clause.to_string(), Box::new(value)));
    self
  }

  pub fn build(self) -> (String, Vec<Box<dyn ToSql + Sync + Send>>) {
    let mut sql = format!("UPDATE {} SET ", self.table);

    for i in 0..self.sets.len() {
      if i > 0 {
        sql.push_str(", ");
      }
      sql.push_str(&format!("{} = ${}", self.sets[i].0, i + 1));
    }

    let mut params: Vec<_> = self.sets.into_iter().map(|(_, value)| value).collect();

    if let Some((clause, value)) = self.where_clause {
      sql.push_str(&format!(" WHERE {} = ${}", clause, params.len() + 1));
      params.push(value);
    }

    (sql, params)
  }
}

pub struct SelectSqlBuilder {
  table: String,
  columns: Vec<String>,
  where_clause: Option<(String, Box<dyn ToSql + Sync + Send>)>,
}

impl SelectSqlBuilder {
  pub fn new(table: &str) -> Self {
    Self {
      table: table.to_string(),
      columns: Vec::new(),
      where_clause: None,
    }
  }

  pub fn column(mut self, column: &str) -> Self {
    self.columns.push(column.to_string());
    self
  }

  pub fn where_clause<T: 'static + ToSql + Sync + Send>(mut self, clause: &str, value: T) -> Self {
    self.where_clause = Some((clause.to_string(), Box::new(value)));
    self
  }

  pub fn build(self) -> (String, Vec<Box<dyn ToSql + Sync + Send>>) {
    let mut sql = format!("SELECT {} FROM {}", self.columns.join(", "), self.table);

    let mut params: Vec<_> = Vec::new();

    if let Some((clause, value)) = self.where_clause {
      sql.push_str(&format!(" WHERE {} = ${}", clause, params.len() + 1));
      params.push(value);
    }

    (sql, params)
  }
}

// #[async_trait]
// impl RemoteCollabStorage for PostgresDB {
//   async fn get_all_updates(&self, object_id: &str) -> Result<Vec<Vec<u8>>, anyhow::Error> {
//     let value_columns = "value";
//     let statement = format!(
//       "SELECT {} FROM af_collab WHERE id = '{}' ORDER BY key;",
//       value_columns, object_id
//     );
//     let rows = self.client.query(&statement, &[]).await?;
//     Ok(
//       rows
//         .into_iter()
//         .map(|row| row.get("value"))
//         .collect::<Vec<_>>(),
//     )
//   }
//
//   async fn send_update(&self, id: MsgId, update: Vec<u8>) -> Result<(), anyhow::Error> {
//     self
//       .client
//       .execute(
//         "INSERT INTO af_collab (key, value) VALUES ($1, $2)",
//         &[&id.to_string(), &update],
//       )
//       .await?;
//     Ok(())
//   }
// }

pub struct PostgresConfiguration {
  pub url: String,
  pub user_name: String,
  pub password: String,
  pub port: u16,
}

const SUPABASE_DB: &str = "SUPABASE_DB";
const SUPABASE_DB_USER: &str = "SUPABASE_DB_USER";
const SUPABASE_DB_PASSWORD: &str = "SUPABASE_DB_PASSWORD";
const SUPABASE_DB_PORT: &str = "SUPABASE_DB_PORT";

impl PostgresConfiguration {
  pub fn from_env() -> Option<Self> {
    let url = std::env::var(SUPABASE_DB).ok()?;
    let user_name = std::env::var(SUPABASE_DB_USER).ok()?;
    let password = std::env::var(SUPABASE_DB_PASSWORD).ok()?;
    let port = std::env::var(SUPABASE_DB_PORT).ok()?.parse::<u16>().ok()?;

    Some(Self {
      url,
      user_name,
      password,
      port,
    })
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  // ‼️‼️‼️ Warning: this test will create a table in the database
  #[tokio::test]
  async fn test_postgres_db() -> Result<(), anyhow::Error> {
    if dotenv::from_filename(".env.test2").is_err() {
      return Ok(());
    }

    let _db = PostgresDB::from_env().await?;
    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
    Ok(())
  }
}
