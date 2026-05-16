#[derive(Debug, thiserror::Error)]
pub enum Error {
  #[error("Migration error: {0}")]
  Migration(#[from] diesel_migrations::MigrationError),
  #[error("r2d2 error: {0}")]
  R2D2(#[from] r2d2::Error),
  #[error("diesel error: {0}")]
  Diesel(#[from] diesel::result::Error),
  #[error("diesel connect error: {0}")]
  Connect(#[from] diesel::ConnectionError),
  #[error("internal error: {0}")]
  Internal(#[from] anyhow::Error),
}

pub type Result<T> = std::result::Result<T, Error>;
