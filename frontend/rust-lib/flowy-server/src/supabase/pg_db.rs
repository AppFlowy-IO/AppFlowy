use std::sync::Arc;

use tokio_postgres::types::ToSql;
use tokio_postgres::{Client, NoTls};

use crate::supabase::migration::run_migrations;

pub type PostgresClient = Client;
pub struct PostgresDB {
  pub configuration: PostgresConfiguration,
  pub client: Arc<PostgresClient>,
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

    // Run migrations
    run_migrations(&mut client).await?;
    Ok(Self {
      configuration,
      client: Arc::new(client),
    })
  }
}

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
  use crate::supabase::migration::run_initial_drop;

  use super::*;

  // ‼️‼️‼️ Warning: this test will create a table in the database
  #[tokio::test]
  async fn test_postgres_db() -> Result<(), anyhow::Error> {
    if dotenv::from_filename(".env.user.test").is_err() {
      return Ok(());
    }

    let configuration = PostgresConfiguration::from_env()
      .ok_or_else(|| anyhow::anyhow!("PostgresConfiguration not found in env"))?;
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

    run_initial_drop(&client).await;
    Ok(())
  }
}
