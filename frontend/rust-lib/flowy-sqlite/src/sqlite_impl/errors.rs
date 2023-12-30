#[derive(Debug, thiserror::Error)]
pub enum Error {
  #[error("Migration error: {0}")]
  MigrationError(#[from] diesel_migrations::MigrationError),
  #[error("r2d2 error: {0}")]
  R2D2Error(#[from] r2d2::Error),
  #[error("diesel error: {0}")]
  DieselError(#[from] diesel::result::Error),
  #[error("diesel connect error: {0}")]
  ConnectionError(#[from] diesel::ConnectionError),
  #[error("io error: {0}")]
  IoError(#[from] std::io::Error),
  #[error("internal error: {0}")]
  Internal(#[from] anyhow::Error),
}

pub type Result<T> = std::result::Result<T, Error>;
