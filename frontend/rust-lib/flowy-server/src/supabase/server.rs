use flowy_search_pub::cloud::SearchCloudService;
use std::collections::HashMap;
use std::sync::{Arc, Weak};

use collab_entity::CollabObject;
use collab_plugins::cloud_storage::{RemoteCollabStorage, RemoteUpdateSender};

use flowy_database_pub::cloud::{DatabaseAIService, DatabaseCloudService};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_server_pub::supabase_config::SupabaseConfiguration;
use flowy_storage_pub::cloud::StorageCloudService;
use flowy_user_pub::cloud::UserCloudService;

use crate::supabase::api::{
  RESTfulPostgresServer, RealtimeCollabUpdateHandler, RealtimeEventHandler, RealtimeUserHandler,
  SupabaseCollabStorageImpl, SupabaseDatabaseServiceImpl, SupabaseDocumentServiceImpl,
  SupabaseFolderServiceImpl, SupabaseServerServiceImpl, SupabaseUserServiceImpl,
};

use crate::{AppFlowyEncryption, AppFlowyServer};

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

pub type CollabUpdateSenderByOid = RwLock<HashMap<String, RemoteUpdateSender>>;
/// Supabase server is used to provide the implementation of the [AppFlowyServer] trait.
/// It contains the configuration of the supabase server and the postgres server.
pub struct SupabaseServer {
  #[allow(dead_code)]
  config: SupabaseConfiguration,
  device_id: String,
  #[allow(dead_code)]
  uid: Arc<RwLock<Option<i64>>>,
  collab_update_sender: Arc<CollabUpdateSenderByOid>,
  restful_postgres: Arc<RwLock<Option<Arc<RESTfulPostgresServer>>>>,
  encryption: Weak<dyn AppFlowyEncryption>,
}

impl SupabaseServer {
  pub fn new(
    uid: Arc<RwLock<Option<i64>>>,
    config: SupabaseConfiguration,
    enable_sync: bool,
    device_id: String,
    encryption: Weak<dyn AppFlowyEncryption>,
  ) -> Self {
    let collab_update_sender = Default::default();
    let restful_postgres = if enable_sync {
      Some(Arc::new(RESTfulPostgresServer::new(
        config.clone(),
        encryption.clone(),
      )))
    } else {
      None
    };
    Self {
      config,
      device_id,
      collab_update_sender,
      restful_postgres: Arc::new(RwLock::new(restful_postgres)),
      encryption,
      uid,
    }
  }
}

impl AppFlowyServer for SupabaseServer {
  fn set_enable_sync(&self, uid: i64, enable: bool) {
    tracing::info!("{} supabase sync: {}", uid, enable);

    if enable {
      if self.restful_postgres.read().is_none() {
        let postgres = RESTfulPostgresServer::new(self.config.clone(), self.encryption.clone());
        *self.restful_postgres.write() = Some(Arc::new(postgres));
      }
    } else {
      *self.restful_postgres.write() = None;
    }
  }

  fn user_service(&self) -> Arc<dyn UserCloudService> {
    // handle the realtime collab update event.
    let (user_update_tx, user_update_rx) = tokio::sync::mpsc::channel(1);

    let collab_update_handler = Box::new(RealtimeCollabUpdateHandler::new(
      Arc::downgrade(&self.collab_update_sender),
      self.device_id.clone(),
      self.encryption.clone(),
    ));

    // handle the realtime user event.
    let user_handler = Box::new(RealtimeUserHandler(user_update_tx));

    let handlers: Vec<Box<dyn RealtimeEventHandler>> = vec![collab_update_handler, user_handler];
    Arc::new(SupabaseUserServiceImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
      handlers,
      Some(user_update_rx),
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

  fn database_ai_service(&self) -> Option<Arc<dyn DatabaseAIService>> {
    None
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(SupabaseDocumentServiceImpl::new(SupabaseServerServiceImpl(
      self.restful_postgres.clone(),
    )))
  }

  fn collab_storage(&self, collab_object: &CollabObject) -> Option<Arc<dyn RemoteCollabStorage>> {
    let (tx, rx) = tokio::sync::mpsc::unbounded_channel();
    self
      .collab_update_sender
      .write()
      .insert(collab_object.object_id.clone(), tx);

    Some(Arc::new(SupabaseCollabStorageImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
      Some(rx),
      self.encryption.clone(),
    )))
  }

  fn file_storage(&self) -> Option<Arc<dyn StorageCloudService>> {
    None
  }

  fn search_service(&self) -> Option<Arc<dyn SearchCloudService>> {
    None
  }
}
