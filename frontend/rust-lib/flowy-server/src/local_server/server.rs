use std::sync::Arc;

use parking_lot::RwLock;
use tokio::sync::mpsc;

use flowy_user::event_map::UserAuthService;

use crate::local_server::user::LocalServerUserAuthServiceImpl;
use crate::AppFlowyServer;

#[derive(Default)]
pub struct LocalServer {
  stop_tx: RwLock<Option<mpsc::Sender<()>>>,
}

impl LocalServer {
  pub fn new() -> Self {
    // let _config = self_host_server_configuration().unwrap();
    Self::default()
  }

  pub async fn stop(&self) {
    let sender = self.stop_tx.read().clone();
    if let Some(stop_tx) = sender {
      let _ = stop_tx.send(()).await;
    }
  }
}

impl AppFlowyServer for LocalServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(LocalServerUserAuthServiceImpl())
  }
}
