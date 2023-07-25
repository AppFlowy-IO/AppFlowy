use std::sync::{Arc, Weak};

use futures_util::future::BoxFuture;
use tokio::sync::oneshot::channel;

use crate::supabase::collab_storage_impls::pooler::{
  PostgresObject, PostgresServer, SupabaseServerService,
};
use crate::supabase::PgPoolMode;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use lib_infra::future::FutureResult;

pub fn try_upgrade_server(
  weak_server: FlowyResult<Weak<PostgresServer>>,
) -> FlowyResult<Arc<PostgresServer>> {
  match weak_server?.upgrade() {
    None => Err(FlowyError::new(
      ErrorCode::PgDatabaseError,
      "Server is close",
    )),
    Some(server) => Ok(server),
  }
}

pub fn execute_async<F, R, T>(service: &T, func: F) -> FutureResult<R, FlowyError>
where
  T: SupabaseServerService,
  F: FnOnce(PostgresObject, PgPoolMode) -> BoxFuture<'static, FlowyResult<R>>
    + Sync
    + Send
    + 'static,
  R: Send + Sync + 'static,
{
  let pg_mode = service.get_pg_mode();
  let weak_server = service.try_get_pg_server();
  let (tx, rx) = channel();
  tokio::spawn(async move {
    let result = async move {
      let server = try_upgrade_server(weak_server)?;
      let client = server.get_pg_client().await.recv().await?;
      (func)(client, pg_mode).await
    }
    .await;
    let _ = tx.send(result);
  });
  FutureResult::new(async { rx.await.map_err(internal_error)? })
}
