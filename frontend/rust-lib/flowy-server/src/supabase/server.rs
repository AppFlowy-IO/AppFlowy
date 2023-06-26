use std::cmp::Ordering;
use std::fmt::{Debug, Formatter, Write};
use std::sync::Arc;

use tokio::sync::mpsc::Receiver;
use tokio::sync::Mutex;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder2::deps::FolderCloudService;
use flowy_user::event_map::UserAuthService;

use crate::supabase::impls::{SupabaseFolderCloudServiceImpl, SupabaseUserAuthServiceImpl};
use crate::supabase::pg_db::{PostgresClient, PostgresDB};
use crate::supabase::{PostgresConfiguration, SupabaseConfiguration};
use crate::AppFlowyServer;

use crate::supabase::queue::RequestState::Pending;
use crate::supabase::queue::{PendingRequest, RequestPayload, RequestQueue};
use async_stream::stream;
use futures::stream::StreamExt;

/// Supabase server is used to provide the implementation of the [AppFlowyServer] trait.
/// It contains the configuration of the supabase server and the postgres server.
pub struct SupabaseServer {
  config: SupabaseConfiguration,
  postgres: Arc<PostgresServer>,
}

impl SupabaseServer {
  pub fn new(config: SupabaseConfiguration) -> Self {
    let postgres = PostgresServer::new(config.postgres_config.clone());
    Self {
      config,
      postgres: Arc::new(postgres),
    }
  }
}

pub(crate) struct PostgresServer {
  db: Arc<Mutex<Option<Arc<PostgresDB>>>>,
  config: PostgresConfiguration,
  pg_requests: Arc<parking_lot::Mutex<RequestQueue<PostgresEvent>>>,
}

impl PostgresServer {
  pub(crate) fn new(config: PostgresConfiguration) -> Self {
    let db = Arc::new(Default::default());
    let pg_requests = Arc::new(parking_lot::Mutex::new(RequestQueue::new()));
    Self {
      db,
      config,
      pg_requests,
    }
  }

  pub(crate) async fn pg_client2(&self) -> PgClientReceiver {
    let (tx, rx) = tokio::sync::mpsc::channel(1);
    let mut pg_requests = self.pg_requests.lock();
    let event = PostgresEvent::GetPgClient { id: 0, sender: tx };
    let request = PendingRequest::new(event);
    pg_requests.push(request);
    rx
  }

  pub(crate) async fn pg_client(&self) -> Result<Arc<PostgresClient>, FlowyError> {
    let mut postgres = self.db.lock().await;
    match &*postgres {
      None => match PostgresDB::new(self.config.clone()).await {
        Ok(db) => {
          let db = Arc::new(db);
          *postgres = Some(db.clone());
          Ok(db.client.clone())
        },
        Err(e) => Err(FlowyError::new(ErrorCode::PgConnectError, e.to_string())),
      },
      Some(postgrest) => Ok(postgrest.client.clone()),
    }
  }
}

impl AppFlowyServer for SupabaseServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(SupabaseUserAuthServiceImpl::new(self.postgres.clone()))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(SupabaseFolderCloudServiceImpl::new(self.postgres.clone()))
  }
}

pub type PgClientReceiver = tokio::sync::mpsc::Receiver<Arc<PostgresClient>>;
pub type PgClientSender = tokio::sync::mpsc::Sender<Arc<PostgresClient>>;

#[derive(Clone)]
pub enum PostgresEvent {
  ConnectDB(Arc<Mutex<Option<Arc<PostgresDB>>>>),
  GetPgClient { id: i64, sender: PgClientSender },
}

impl Debug for PostgresEvent {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      PostgresEvent::ConnectDB(_) => f.write_str("ConnectDB"),
      PostgresEvent::GetPgClient { id, .. } => f.write_fmt(format_args!("GetPgClient({})", id)),
    }
  }
}

impl Ord for PostgresEvent {
  fn cmp(&self, other: &Self) -> Ordering {
    match (self, other) {
      (PostgresEvent::ConnectDB(_), PostgresEvent::ConnectDB(_)) => Ordering::Equal,
      (PostgresEvent::ConnectDB(_), PostgresEvent::GetPgClient { .. }) => Ordering::Greater,
      (PostgresEvent::GetPgClient { .. }, PostgresEvent::ConnectDB(_)) => Ordering::Less,
      (PostgresEvent::GetPgClient { id: id1, .. }, PostgresEvent::GetPgClient { id: id2, .. }) => {
        id1.cmp(id2)
      },
    }
  }
}

impl Eq for PostgresEvent {}

impl PartialEq<Self> for PostgresEvent {
  fn eq(&self, other: &Self) -> bool {
    match (self, other) {
      (PostgresEvent::ConnectDB(_), PostgresEvent::ConnectDB(_)) => true,
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
