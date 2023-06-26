use std::cmp::Ordering;
use std::fmt::{Debug, Formatter, Write};
use std::sync::{Arc, Weak};

use tokio::sync::{watch, Mutex};
use tokio_postgres::{Client, NoTls};

use crate::supabase::migration::run_migrations;
use crate::supabase::queue::RequestPayload;
use crate::supabase::{PostgresConfiguration, PostgresServer};

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

pub type PgClientSender = tokio::sync::mpsc::Sender<Arc<PostgresClient>>;

#[derive(Clone)]
pub enum PostgresEvent {
  ConnectDB,
  GetPgClient { id: u32, sender: PgClientSender },
}

impl Debug for PostgresEvent {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      PostgresEvent::ConnectDB => f.write_str("ConnectDB"),
      PostgresEvent::GetPgClient { id, .. } => f.write_fmt(format_args!("GetPgClient({})", id)),
    }
  }
}

impl Ord for PostgresEvent {
  fn cmp(&self, other: &Self) -> Ordering {
    match (self, other) {
      (PostgresEvent::ConnectDB, PostgresEvent::ConnectDB) => Ordering::Equal,
      (PostgresEvent::ConnectDB, PostgresEvent::GetPgClient { .. }) => Ordering::Greater,
      (PostgresEvent::GetPgClient { .. }, PostgresEvent::ConnectDB) => Ordering::Less,
      (PostgresEvent::GetPgClient { id: id1, .. }, PostgresEvent::GetPgClient { id: id2, .. }) => {
        id1.cmp(id2).reverse()
      },
    }
  }
}

impl Eq for PostgresEvent {}

impl PartialEq<Self> for PostgresEvent {
  fn eq(&self, other: &Self) -> bool {
    match (self, other) {
      (PostgresEvent::ConnectDB, PostgresEvent::ConnectDB) => true,
      (PostgresEvent::GetPgClient { id: id1, .. }, PostgresEvent::GetPgClient { id: id2, .. }) => {
        id1 == id2
      },
      _ => false,
    }
  }
}

impl PartialOrd<Self> for PostgresEvent {
  fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
    Some(self.cmp(other))
  }
}

impl RequestPayload for PostgresEvent {}

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
