use std::collections::HashMap;
use std::sync::Arc;

use collab_plugins::cloud_storage::{CollabObject, RemoteCollabStorage, RemoteUpdateSender};
use parking_lot::{Mutex, RwLock};
use serde_json::Value;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_user_deps::cloud::UserService;

use crate::supabase::api::{
  RESTfulPostgresServer, RESTfulSupabaseUserAuthServiceImpl, SupabaseCollabStorageImpl,
  SupabaseDatabaseServiceImpl, SupabaseDocumentServiceImpl, SupabaseFolderServiceImpl,
  SupabaseServerServiceImpl,
};
use crate::supabase::entities::RealtimeCollabUpdateEvent;
use crate::AppFlowyServer;

/// https://www.pgbouncer.org/features.html
/// Only support session mode.
///
/// Session mode:
/// When a new client connects, a connection is assigned to the client until it disconnects. Afterward,
/// the connection is returned back to the pool. All PostgreSQL features can be used with this option.
/// For the moment, the default pool size of pgbouncer in supabase is 15 in session mode. Which means
/// that we can have 15 concurrent connections to the database.
///
/// Transaction mode:
/// This is the suggested option for serverless functions. With this, the connection is only assigned
/// to the client for the duration of a transaction. Once done, the connection is returned to the pool.
/// Two consecutive transactions from the same client could be done over two, different connections.
/// Some session-based PostgreSQL features such as prepared statements are not available with this option.
/// A more comprehensive list of incompatible features can be found here.
///
/// Most of the case, Session mode is faster than Transaction mode(no statement cache(https://github.com/supabase/supavisor/issues/69) and queue transaction).
/// But Transaction mode is more suitable for serverless functions. It can reduce the number of concurrent
/// connections to the database.
/// TODO(nathan): fix prepared statement error when using transaction mode. https://github.com/prisma/prisma/issues/11643
///
#[derive(Clone, Debug, Default)]
pub enum PgPoolMode {
  #[default]
  Session,
  Transaction,
}

impl PgPoolMode {
  pub fn support_prepare_cached(&self) -> bool {
    matches!(self, PgPoolMode::Session)
  }
}
/// Supabase server is used to provide the implementation of the [AppFlowyServer] trait.
/// It contains the configuration of the supabase server and the postgres server.
pub struct SupabaseServer {
  #[allow(dead_code)]
  config: SupabaseConfiguration,
  device_id: Mutex<String>,
  update_tx: RwLock<HashMap<String, RemoteUpdateSender>>,
  restful_postgres: Arc<RwLock<Option<Arc<RESTfulPostgresServer>>>>,
}

impl SupabaseServer {
  pub fn new(config: SupabaseConfiguration) -> Self {
    let update_tx = RwLock::new(HashMap::new());
    let restful_postgres = if config.enable_sync {
      Some(Arc::new(RESTfulPostgresServer::new(config.clone())))
    } else {
      None
    };
    Self {
      config,
      device_id: Default::default(),
      update_tx,
      restful_postgres: Arc::new(RwLock::new(restful_postgres)),
    }
  }

  pub fn set_enable_sync(&self, enable: bool) {
    if enable {
      if self.restful_postgres.read().is_some() {
        return;
      }
      *self.restful_postgres.write() =
        Some(Arc::new(RESTfulPostgresServer::new(self.config.clone())));
    } else {
      *self.restful_postgres.write() = None;
    }
  }
}

impl AppFlowyServer for SupabaseServer {
  fn enable_sync(&self, enable: bool) {
    tracing::info!("supabase sync: {}", enable);
    self.set_enable_sync(enable);
  }

  fn set_sync_device_id(&self, device_id: &str) {
    *self.device_id.lock() = device_id.to_string();
  }

  fn user_service(&self) -> Arc<dyn UserService> {
    Arc::new(RESTfulSupabaseUserAuthServiceImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
    ))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(SupabaseFolderServiceImpl::new(SupabaseServerServiceImpl(
      self.restful_postgres.clone(),
    )))
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(SupabaseDatabaseServiceImpl::new(SupabaseServerServiceImpl(
      self.restful_postgres.clone(),
    )))
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(SupabaseDocumentServiceImpl::new(SupabaseServerServiceImpl(
      self.restful_postgres.clone(),
    )))
  }

  fn collab_storage(&self, collab_object: &CollabObject) -> Option<Arc<dyn RemoteCollabStorage>> {
    let (tx, rx) = tokio::sync::mpsc::unbounded_channel();
    self
      .update_tx
      .write()
      .insert(collab_object.object_id.clone(), tx);
    Some(Arc::new(SupabaseCollabStorageImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
      Some(rx),
    )))
  }

  fn handle_realtime_event(&self, json: Value) {
    match serde_json::from_value::<RealtimeCollabUpdateEvent>(json) {
      Ok(event) => {
        if let Some(tx) = self.update_tx.read().get(event.payload.oid.as_str()) {
          if self.device_id.lock().as_str() != event.payload.did.as_str() {
            if let Err(e) = tx.send(event.payload.value) {
              tracing::trace!("send realtime update error: {}", e);
            }
          }
        }
      },
      Err(e) => {
        tracing::error!("parser realtime event error: {}", e);
      },
    }
  }
}
