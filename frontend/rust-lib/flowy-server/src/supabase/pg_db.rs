use std::sync::Arc;

use tokio_postgres::{Client, NoTls};

use crate::supabase::migration::run_migrations;
use crate::supabase::PostgresConfiguration;

pub type PostgresClient = Client;
pub struct PostgresDB {
  pub configuration: PostgresConfiguration,
  pub client: Arc<PostgresClient>,
}

impl PostgresDB {
  #[allow(dead_code)]
  pub async fn from_env() -> Result<Self, anyhow::Error> {
    let configuration = PostgresConfiguration::from_env()?;
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

    let configuration = PostgresConfiguration::from_env().unwrap();
    let mut config = tokio_postgres::Config::new();
    config
      .host(&configuration.url)
      .user(&configuration.user_name)
      .password(&configuration.password)
      .port(configuration.port);

    // Using the https://docs.rs/postgres-openssl/latest/postgres_openssl/ to enable tls connection.
    let (client, connection) = config.connect(NoTls).await?;
    tokio::spawn(async move {
      if let Err(e) = connection.await {
        tracing::error!("postgres db connection error: {}", e);
      }
    });

    run_initial_drop(&client).await;
    Ok(())
  }
}
