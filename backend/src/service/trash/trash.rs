use anyhow::Context;
use flowy_net::{errors::ServerError, response::FlowyResponse};
use flowy_workspace::protobuf::Trash;
use sqlx::PgPool;

pub(crate) async fn create_trash(pool: &PgPool, _params: Trash) -> Result<FlowyResponse, ServerError> {
    let transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create trash")?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to trash view.")?;

    Ok(FlowyResponse::success())
}
