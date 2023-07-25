use std::ops::Deref;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, Weak};
use std::time::Duration;

use parking_lot::RwLock;
use tokio::spawn;
use tokio::sync::{watch, Mutex};
use tokio::time::interval;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_server_config::supabase_config::PostgresConfiguration;
use lib_infra::async_trait::async_trait;

use crate::supabase::queue::{
  PendingRequest, RequestHandler, RequestQueue, RequestRunner, RequestState,
};
use crate::supabase::storage_impls::pooler::{PgClientReceiver, PostgresEvent, PostgresPool};
use crate::supabase::PgPoolMode;

pub struct PostgresServer {
  mode: PgPoolMode,
  request_handler: Arc<PostgresRequestHandler>,
}

impl Deref for PostgresServer {
  type Target = Arc<PostgresRequestHandler>;

  fn deref(&self) -> &Self::Target {
    &self.request_handler
  }
}

impl PostgresServer {
  pub fn new(mode: PgPoolMode, config: PostgresConfiguration) -> Self {
    let (runner_notifier_tx, runner_notifier) = watch::channel(false);
    let request_handler = Arc::new(PostgresRequestHandler::new(runner_notifier_tx, config));

    // Initialize the connection to the database
    let conn = PendingRequest::new(PostgresEvent::ConnectDB);
    request_handler.queue.lock().push(conn);
    let handler = Arc::downgrade(&request_handler) as Weak<dyn RequestHandler<PostgresEvent>>;
    spawn(RequestRunner::run(runner_notifier, handler));

    Self {
      mode,
      request_handler,
    }
  }
}

pub struct PostgresRequestHandler {
  config: PostgresConfiguration,
  pool: Arc<Mutex<Option<Arc<PostgresPool>>>>,
  queue: parking_lot::Mutex<RequestQueue<PostgresEvent>>,
  runner_notifier: Arc<watch::Sender<bool>>,
  sequence: AtomicU32,
}

impl PostgresRequestHandler {
  pub fn new(runner_notifier: watch::Sender<bool>, config: PostgresConfiguration) -> Self {
    let pool = Arc::new(Default::default());
    let queue = parking_lot::Mutex::new(RequestQueue::new());
    let runner_notifier = Arc::new(runner_notifier);
    Self {
      pool,
      queue,
      runner_notifier,
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

#[async_trait]
impl RequestHandler<PostgresEvent> for PostgresRequestHandler {
  async fn prepare_request(&self) -> Option<PendingRequest<PostgresEvent>> {
    match self.queue.try_lock() {
      None => {
        // If acquire the lock failed, try after 300ms
        let weak_notifier = Arc::downgrade(&self.runner_notifier);
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
        let is_connected = self.pool.lock().await.is_some();
        if is_connected {
          tracing::warn!("Already connect to postgres db");
        } else {
          tracing::info!("Start connecting to postgres db");
          match PostgresPool::new(self.config.clone()).await {
            Ok(db) => {
              *self.pool.lock().await = Some(Arc::new(db));
              if let Some(mut request) = self.queue.lock().pop() {
                request.set_state(RequestState::Done);
              }
            },
            Err(e) => {
              tracing::error!("Error connecting to the postgres db: {}", e);
              tokio::time::sleep(Duration::from_secs(5)).await;
            },
          }
        }
      },
      PostgresEvent::GetPgClient { id: _, sender } => {
        match self.pool.lock().await.as_ref().cloned() {
          None => {
            tokio::time::sleep(Duration::from_secs(5)).await;
            tracing::error!("Can't get the postgres client");
          },
          Some(pool) => {
            match pool.get().await {
              Ok(object) => {
                if let Err(e) = sender.send(object).await {
                  tracing::error!("Error sending the postgres client: {}", e);
                }
              },
              Err(e) => tracing::error!("Get postgres client failed: {}", e),
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
    let _ = self.runner_notifier.send(false);
  }
}

/// [SupabaseServerService] is used to provide supabase services. The caller can using this trait
/// to get the services and it might need to handle the situation when the services is unavailable.
/// For example, when user stop syncing, the services will be unavailable or when the user is logged
/// out.
pub trait SupabaseServerService: Send + Sync + 'static {
  fn get_pg_mode(&self) -> PgPoolMode;

  fn get_pg_server(&self) -> Option<Weak<PostgresServer>>;

  fn try_get_pg_server(&self) -> FlowyResult<Weak<PostgresServer>>;
}

#[derive(Clone)]
pub struct SupabaseServerServiceImpl(pub Arc<RwLock<Option<Arc<PostgresServer>>>>);
impl SupabaseServerService for SupabaseServerServiceImpl {
  fn get_pg_mode(&self) -> PgPoolMode {
    self
      .0
      .read()
      .as_ref()
      .map(|server| server.mode.clone())
      .unwrap_or_default()
  }

  /// Get the postgres server, if the postgres server is not available, return None.
  fn get_pg_server(&self) -> Option<Weak<PostgresServer>> {
    self.0.read().as_ref().map(Arc::downgrade)
  }

  /// Try to get the postgres server, if the postgres server is not available, return an error.
  fn try_get_pg_server(&self) -> FlowyResult<Weak<PostgresServer>> {
    self.0.read().as_ref().map(Arc::downgrade).ok_or_else(|| {
      FlowyError::new(
        ErrorCode::SupabaseSyncRequired,
        "Supabase sync is disabled, please enable it first",
      )
    })
  }
}
