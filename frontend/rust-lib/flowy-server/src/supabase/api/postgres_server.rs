use anyhow::Error;
use parking_lot::RwLock;
use std::ops::Deref;
use std::sync::{Arc, Weak};

use flowy_error::{ErrorCode, FlowyError};
use postgrest::Postgrest;

use flowy_server_config::supabase_config::SupabaseConfiguration;

/// Creates a wrapper for Postgrest, which allows us to extend the functionality of Postgrest.
pub struct PostgresWrapper(Postgrest);

impl Deref for PostgresWrapper {
  type Target = Postgrest;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

pub struct RESTfulPostgresServer {
  pub postgrest: Arc<PostgresWrapper>,
}

impl RESTfulPostgresServer {
  pub fn new(config: SupabaseConfiguration) -> Self {
    let url = format!("{}/rest/v1", config.url);
    let auth = format!("Bearer {}", config.anon_key);
    let postgrest = Postgrest::new(url)
      .insert_header("apikey", config.anon_key)
      .insert_header("Authorization", auth);
    Self {
      postgrest: Arc::new(PostgresWrapper(postgrest)),
    }
  }
}

pub trait SupabaseServerService: Send + Sync + 'static {
  fn get_postgrest(&self) -> Option<Arc<PostgresWrapper>>;
  fn try_get_postgrest(&self) -> Result<Arc<PostgresWrapper>, Error>;
  fn try_get_weak_postgrest(&self) -> Result<Weak<PostgresWrapper>, Error>;
}

#[derive(Clone)]
pub struct SupabaseServerServiceImpl(pub Arc<RwLock<Option<Arc<RESTfulPostgresServer>>>>);

impl SupabaseServerServiceImpl {
  pub fn new(postgrest: Arc<RESTfulPostgresServer>) -> Self {
    Self(Arc::new(RwLock::new(Some(postgrest))))
  }
}

impl SupabaseServerService for SupabaseServerServiceImpl {
  fn get_postgrest(&self) -> Option<Arc<PostgresWrapper>> {
    self
      .0
      .read()
      .as_ref()
      .map(|server| server.postgrest.clone())
  }

  fn try_get_postgrest(&self) -> Result<Arc<PostgresWrapper>, Error> {
    self
      .0
      .read()
      .as_ref()
      .map(|server| server.postgrest.clone())
      .ok_or_else(|| {
        FlowyError::new(
          ErrorCode::SupabaseSyncRequired,
          "Supabase sync is disabled, please enable it first",
        )
        .into()
      })
  }

  fn try_get_weak_postgrest(&self) -> Result<Weak<PostgresWrapper>, Error> {
    let postgrest = self.try_get_postgrest()?;
    Ok(Arc::downgrade(&postgrest))
  }
}
