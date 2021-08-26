use flowy_net::errors::{ErrorCode, ServerError};
use sqlx::{Error, Postgres, Transaction};

pub type DBTransaction<'a> = Transaction<'a, Postgres>;

pub fn map_sqlx_error(error: sqlx::Error) -> ServerError {
    match error {
        Error::RowNotFound => ServerError::new("".to_string(), ErrorCode::RecordNotFound),
        _ => ServerError::internal().context(error),
    }
}
