use std::sync::mpsc::Receiver;
use std::sync::Arc;

use serde::Deserialize;
use tokio::sync::Mutex;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder2::deps::FolderCloudService;
use flowy_user::event_map::UserAuthService;

use crate::supabase::impls::{SupabaseFolderCloudServiceImpl, SupabaseUserAuthServiceImpl};
use crate::supabase::pg_db::{PostgresClient, PostgresDB};
use crate::supabase::{PostgresConfiguration, SupabaseConfiguration};
use crate::AppFlowyServer;

pub struct SupabaseServer {
  pub config: SupabaseConfiguration,
  pub postgres: Arc<PostgresServer>,
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

pub struct PostgresServer {
  db: Arc<Mutex<Option<Arc<PostgresDB>>>>,
  config: PostgresConfiguration,
}

impl PostgresServer {
  pub fn new(config: PostgresConfiguration) -> Self {
    Self {
      db: Arc::new(Default::default()),
      config,
    }
  }

  pub async fn pg_client(&self) -> Result<Arc<PostgresClient>, FlowyError> {
    let mut postgres = self.db.lock().await;
    match &*postgres {
      None => match PostgresDB::new(self.config.clone()).await {
        Ok(db) => {
          let db = Arc::new(db);
          *postgres = Some(db.clone());
          Ok(db.client.clone())
        },
        Err(e) => Err(FlowyError::new(
          ErrorCode::PostgresDatabaseConnectError,
          e.to_string(),
        )),
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

struct SupabaseServerRunner(Receiver<()>);
