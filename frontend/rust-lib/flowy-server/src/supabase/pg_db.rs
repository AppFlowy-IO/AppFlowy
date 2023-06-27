use std::cmp::Ordering;
use std::fmt::{Debug, Formatter, Write};
use std::sync::Arc;

use deadpool_postgres::{Manager, ManagerConfig, Object, Pool, RecyclingMethod};
use tokio_postgres::{Client, NoTls};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::supabase::migration::run_migrations;
use crate::supabase::queue::RequestPayload;
use crate::supabase::PostgresConfiguration;

pub type PostgresClient = Client;
pub type PostgresObject = Object;
pub struct PostgresDB {
  pub configuration: PostgresConfiguration,
  pub client: Arc<Pool>,
}

impl PostgresDB {
  #[allow(dead_code)]
  pub async fn from_env() -> Result<Self, anyhow::Error> {
    let configuration = PostgresConfiguration::from_env()?;
    Self::new(configuration).await
  }

  pub async fn new(configuration: PostgresConfiguration) -> Result<Self, anyhow::Error> {
    let mut pg_config = tokio_postgres::Config::new();
    pg_config
      .host(&configuration.url)
      .user(&configuration.user_name)
      .password(&configuration.password)
      .port(configuration.port);

    let mgr_config = ManagerConfig {
      recycling_method: RecyclingMethod::Fast,
    };

    // Using the https://docs.rs/postgres-openssl/latest/postgres_openssl/ to enable tls connection.
    let mgr = Manager::from_config(pg_config, NoTls, mgr_config);
    let pool = Pool::builder(mgr).max_size(16).build()?;
    let mut client = pool.get().await?;
    // Run migrations
    run_migrations(&mut client).await?;

    Ok(Self {
      configuration,
      client: Arc::new(pool),
    })
  }
}

pub type PgClientSender = tokio::sync::mpsc::Sender<PostgresObject>;

pub struct PgClientReceiver(pub tokio::sync::mpsc::Receiver<PostgresObject>);
impl PgClientReceiver {
  pub async fn recv(&mut self) -> FlowyResult<PostgresObject> {
    match self.0.recv().await {
      None => Err(FlowyError::new(
        ErrorCode::PgConnectError,
        "Can't connect to the postgres db".to_string(),
      )),
      Some(object) => Ok(object),
    }
  }
}

#[derive(Clone)]
pub enum PostgresEvent {
  ConnectDB,
  /// The ID is utilized to sequence the events within the priority queue.
  /// The sender is employed for transmitting the PostgresObject back to the original sender.
  /// At present, the sender is invoked subsequent to the processing of the previous PostgresObject.
  /// For future optimizations, we could potentially perform batch processing of the [GetPgClient] events utilizing the [Pool].
  GetPgClient {
    id: u32,
    sender: PgClientSender,
  },
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
