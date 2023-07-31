use std::sync::Arc;

use collab_plugins::cloud_storage::RemoteCollabStorage;
use parking_lot::RwLock;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_user_deps::cloud::UserService;

use crate::supabase::api::{
  RESTfulPostgresServer, RESTfulSupabaseCollabStorageImpl, RESTfulSupabaseDatabaseServiceImpl,
  RESTfulSupabaseDocumentServiceImpl, RESTfulSupabaseFolderServiceImpl,
  RESTfulSupabaseUserAuthServiceImpl, SupabaseServerServiceImpl,
};
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
  restful_postgres: Arc<RwLock<Option<Arc<RESTfulPostgresServer>>>>,
}

impl SupabaseServer {
  pub fn new(config: SupabaseConfiguration) -> Self {
    let restful_postgres = if config.enable_sync {
      Some(Arc::new(RESTfulPostgresServer::new(config.clone())))
    } else {
      None
    };
    Self {
      config,
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

  fn user_service(&self) -> Arc<dyn UserService> {
    Arc::new(RESTfulSupabaseUserAuthServiceImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
    ))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(RESTfulSupabaseFolderServiceImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
    ))
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(RESTfulSupabaseDatabaseServiceImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
    ))
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(RESTfulSupabaseDocumentServiceImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
    ))
  }

  fn collab_storage(&self) -> Option<Arc<dyn RemoteCollabStorage>> {
    Some(Arc::new(RESTfulSupabaseCollabStorageImpl::new(
      SupabaseServerServiceImpl(self.restful_postgres.clone()),
    )))
  }
}
