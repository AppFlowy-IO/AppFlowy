use std::ops::Deref;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, Weak};
use std::time::Duration;

use futures_util::SinkExt;
use tokio::spawn;
use tokio::sync::mpsc::error::SendError;
use tokio::sync::{watch, Mutex};
use tokio::time::interval;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder2::deps::FolderCloudService;
use flowy_user::event_map::UserAuthService;
use lib_infra::async_trait::async_trait;

use crate::supabase::impls::{SupabaseFolderCloudServiceImpl, SupabaseUserAuthServiceImpl};
use crate::supabase::pg_db::{PostgresClient, PostgresDB, PostgresEvent};
use crate::supabase::queue::{
  PendingRequest, RequestHandler, RequestQueue, RequestRunner, RequestState,
};
use crate::supabase::{PostgresConfiguration, SupabaseConfiguration};
use crate::AppFlowyServer;

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

impl AppFlowyServer for SupabaseServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(SupabaseUserAuthServiceImpl::new(self.postgres.clone()))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(SupabaseFolderCloudServiceImpl::new(self.postgres.clone()))
  }
}

pub(crate) struct PostgresServer {
  inner: Arc<PostgresServerInner>,
}

impl Deref for PostgresServer {
  type Target = Arc<PostgresServerInner>;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

pub(crate) struct PostgresServerInner {
  config: PostgresConfiguration,
  db: Arc<Mutex<Option<Arc<PostgresDB>>>>,
  queue: parking_lot::Mutex<RequestQueue<PostgresEvent>>,
  notifier: Arc<watch::Sender<bool>>,
  sequence: AtomicU32,
}

impl PostgresServerInner {
  pub(crate) fn new(notifier: watch::Sender<bool>, config: PostgresConfiguration) -> Self {
    let db = Arc::new(Default::default());
    let queue = parking_lot::Mutex::new(RequestQueue::new());
    let notifier = Arc::new(notifier);
    Self {
      db,
      queue,
      notifier,
      config,
      sequence: Default::default(),
    }
  }
  pub(crate) async fn get_pg_client(&self) -> PgClientReceiver {
    let (tx, rx) = tokio::sync::mpsc::channel(1);
    let mut queue = self.queue.lock();

    let event = PostgresEvent::GetPgClient {
      id: self.sequence.fetch_add(1, Ordering::SeqCst),
      sender: tx,
    };
    let request = PendingRequest::new(event);
    queue.push(request);
    self.notify();
    PgClientReceiver(rx)
  }
}

impl PostgresServer {
  pub(crate) fn new(config: PostgresConfiguration) -> Self {
    let (notifier, notifier_rx) = watch::channel(false);
    let inner = Arc::new(PostgresServerInner::new(notifier, config));

    // Initialize the connection to the database
    let conn = PendingRequest::new(PostgresEvent::ConnectDB);
    inner.queue.lock().push(conn);
    let handler = Arc::downgrade(&inner) as Weak<dyn RequestHandler>;
    spawn(RequestRunner::run(notifier_rx, handler));

    Self { inner }
  }
}

#[async_trait]
impl RequestHandler for PostgresServerInner {
  async fn process_next_request(&self) -> Option<()> {
    let request = match self.queue.try_lock() {
      None => {
        // If acquire the lock failed, try to notify again after 100ms
        let weak_notifier = Arc::downgrade(&self.notifier);
        spawn(async move {
          interval(Duration::from_millis(100)).tick().await;
          if let Some(mut notifier) = weak_notifier.upgrade() {
            let _ = notifier.send(false);
          }
        });
        None
      },
      Some(mut queue) => queue.pop(),
    }?;

    if request.is_done() {
      self.notify();
      return None;
    }

    if request.is_processing() {
      return None;
    }

    let payload = request.payload.clone();
    self.queue.lock().push(request);

    match payload {
      PostgresEvent::ConnectDB => match PostgresDB::new(self.config.clone()).await {
        Ok(db) => {
          *self.db.lock().await = Some(Arc::new(db));
          if let Some(mut request) = self.queue.lock().peek_mut() {
            request.set_state(RequestState::Done);
          }
          self.notify();
        },
        Err(e) => tracing::error!("Error connecting to the postgres db: {}", e),
      },
      PostgresEvent::GetPgClient { id, sender } => {
        match self.db.lock().await.as_ref().map(|db| db.client.clone()) {
          None => {},
          Some(client) => {
            if let Err(e) = sender.send(client).await {
              tracing::error!("Error sending the postgres client: {}", e);
            }
            if let Some(mut request) = self.queue.lock().peek_mut() {
              request.set_state(RequestState::Done);
            }
            self.notify();
          },
        }
      },
    }
    None
  }

  fn notify(&self) {
    let _ = self.notifier.send(false);
  }
}

pub struct PgClientReceiver(tokio::sync::mpsc::Receiver<Arc<PostgresClient>>);
impl PgClientReceiver {
  pub async fn recv(&mut self) -> FlowyResult<Arc<PostgresClient>> {
    match self.0.recv().await {
      None => Err(FlowyError::new(
        ErrorCode::PgConnectError,
        "Can't connect to the postgres db".to_string(),
      )),
      Some(client) => Ok(client),
    }
  }
}
