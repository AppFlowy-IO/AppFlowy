use std::ops::Deref;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, Weak};
use std::time::Duration;

use futures_util::SinkExt;
use tokio::spawn;
use tokio::sync::{watch, Mutex};
use tokio::time::interval;
use tokio_postgres::GenericClient;

use flowy_folder2::deps::FolderCloudService;
use flowy_user::event_map::UserAuthService;
use lib_infra::async_trait::async_trait;

use crate::supabase::impls::{SupabaseFolderCloudServiceImpl, SupabaseUserAuthServiceImpl};
use crate::supabase::pg_db::{PgClientReceiver, PostgresDB, PostgresEvent};
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

pub struct PostgresServer {
  inner: Arc<PostgresServerInner>,
}

impl Deref for PostgresServer {
  type Target = Arc<PostgresServerInner>;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

pub struct PostgresServerInner {
  config: PostgresConfiguration,
  db: Arc<Mutex<Option<Arc<PostgresDB>>>>,
  queue: parking_lot::Mutex<RequestQueue<PostgresEvent>>,
  notifier: Arc<watch::Sender<bool>>,
  sequence: AtomicU32,
}

impl PostgresServerInner {
  pub fn new(notifier: watch::Sender<bool>, config: PostgresConfiguration) -> Self {
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

  pub async fn get_pg_client(&self) -> PgClientReceiver {
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
  pub fn new(config: PostgresConfiguration) -> Self {
    let (notifier, notifier_rx) = watch::channel(false);
    let inner = Arc::new(PostgresServerInner::new(notifier, config));

    // Initialize the connection to the database
    let conn = PendingRequest::new(PostgresEvent::ConnectDB);
    inner.queue.lock().push(conn);
    let handler = Arc::downgrade(&inner) as Weak<dyn RequestHandler<PostgresEvent>>;
    spawn(RequestRunner::run(notifier_rx, handler));

    Self { inner }
  }
}

#[async_trait]
impl RequestHandler<PostgresEvent> for PostgresServerInner {
  async fn prepare_request(&self) -> Option<PendingRequest<PostgresEvent>> {
    match self.queue.try_lock() {
      None => {
        // If acquire the lock failed, try after 300ms
        let weak_notifier = Arc::downgrade(&self.notifier);
        spawn(async move {
          interval(Duration::from_millis(300)).tick().await;
          if let Some(notifier) = weak_notifier.upgrade() {
            let _ = notifier.send(false);
          }
        });
        None
      },
      Some(queue) => queue.peek().cloned(),
    }
  }

  async fn handle_request(&self, request: PendingRequest<PostgresEvent>) -> Option<()> {
    debug_assert!(Some(&request) == self.queue.lock().peek());

    match request.payload {
      PostgresEvent::ConnectDB => {
        let is_connected = self.db.lock().await.is_some();
        if !is_connected {
          match PostgresDB::new(self.config.clone()).await {
            Ok(db) => {
              *self.db.lock().await = Some(Arc::new(db));
              if let Some(mut request) = self.queue.lock().pop() {
                request.set_state(RequestState::Done);
              }
            },
            Err(e) => tracing::error!("Error connecting to the postgres db: {}", e),
          }
        }
      },
      PostgresEvent::GetPgClient { id: _, sender } => {
        match self.db.lock().await.as_ref().map(|db| db.client.clone()) {
          None => tracing::error!("Can't get the postgres client"),
          Some(pool) => {
            if let Ok(object) = pool.get().await {
              if let Err(e) = sender.send(object).await {
                tracing::error!("Error sending the postgres client: {}", e);
              }
            }

            if let Some(mut request) = self.queue.lock().pop() {
              request.set_state(RequestState::Done);
            }
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
