use af_persistence::store::AppFlowyWASMStore;
use flowy_error::FlowyResult;
use flowy_user_pub::session::Session;
use std::rc::Rc;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct AuthenticateUser {
  session: Arc<RwLock<Option<Session>>>,
  store: Rc<AppFlowyWASMStore>,
}

impl AuthenticateUser {
  pub async fn new(store: Rc<AppFlowyWASMStore>) -> FlowyResult<Self> {
    Ok(Self {
      session: Arc::new(RwLock::new(None)),
      store,
    })
  }
}
