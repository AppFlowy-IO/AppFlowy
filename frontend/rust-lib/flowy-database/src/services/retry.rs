use flowy_client_sync::client_database::GridBlockRevisionPad;
use flowy_error::FlowyError;
use grid_model::RowRevision;
use lib_infra::retry::Action;
use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct GetRowDataRetryAction {
  pub row_id: String,
  pub pad: Arc<RwLock<GridBlockRevisionPad>>,
}

impl Action for GetRowDataRetryAction {
  type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send + Sync>>;
  type Item = Option<(usize, Arc<RowRevision>)>;
  type Error = FlowyError;

  fn run(&mut self) -> Self::Future {
    let pad = self.pad.clone();
    let row_id = self.row_id.clone();
    Box::pin(async move {
      match pad.try_read() {
        Err(_) => Ok(None),
        Ok(read_guard) => Ok(read_guard.get_row_rev(&row_id)),
      }
    })
  }
}
