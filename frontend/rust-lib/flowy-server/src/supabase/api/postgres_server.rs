use std::ops::Deref;
use std::sync::{Arc, Weak};

use anyhow::Error;
use parking_lot::RwLock;
use postgrest::Postgrest;

use flowy_error::{ErrorCode, FlowyError};
use flowy_server_pub::supabase_config::SupabaseConfiguration;

use crate::AppFlowyEncryption;

/// Creates a wrapper for Postgrest, which allows us to extend the functionality of Postgrest.
pub struct PostgresWrapper {
  inner: Postgrest,
  pub encryption: Weak<dyn AppFlowyEncryption>,
}

impl PostgresWrapper {
  pub fn secret(&self) -> Option<String> {
    match self.encryption.upgrade() {
      None => None,
      Some(encryption) => encryption.get_secret(),
    }
  }
}

impl Deref for PostgresWrapper {
  type Target = Postgrest;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

pub struct RESTfulPostgresServer {
  pub postgrest: Arc<PostgresWrapper>,
}

impl RESTfulPostgresServer {
  pub fn new(config: SupabaseConfiguration, encryption: Weak<dyn AppFlowyEncryption>) -> Self {
    let url = format!("{}/rest/v1", config.url);
    let auth = format!("Bearer {}", config.anon_key);
    let postgrest = Postgrest::new(url)
      .insert_header("apikey", config.anon_key)
      .insert_header("Authorization", auth);
    Self {
      postgrest: Arc::new(PostgresWrapper {
        inner: postgrest,
        encryption,
      }),
    }
  }
}

pub trait SupabaseServerService: Send + Sync + 'static {
  fn get_postgrest(&self) -> Option<Arc<PostgresWrapper>>;
  fn try_get_postgrest(&self) -> Result<Arc<PostgresWrapper>, Error>;
  fn try_get_weak_postgrest(&self) -> Result<Weak<PostgresWrapper>, Error>;
}

impl<T> SupabaseServerService for Arc<T>
where
  T: SupabaseServerService,
{
  fn get_postgrest(&self) -> Option<Arc<PostgresWrapper>> {
    (**self).get_postgrest()
  }

  fn try_get_postgrest(&self) -> Result<Arc<PostgresWrapper>, Error> {
    (**self).try_get_postgrest()
  }

  fn try_get_weak_postgrest(&self) -> Result<Weak<PostgresWrapper>, Error> {
    (**self).try_get_weak_postgrest()
  }
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
          ErrorCode::DataSyncRequired,
          "Data Sync is disabled, please enable it first",
        )
        .into()
      })
  }

  fn try_get_weak_postgrest(&self) -> Result<Weak<PostgresWrapper>, Error> {
    let postgrest = self.try_get_postgrest()?;
    Ok(Arc::downgrade(&postgrest))
  }
}
