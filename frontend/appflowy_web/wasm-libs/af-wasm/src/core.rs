use crate::integrate::server::ServerProviderWASM;
use af_user::manager::UserManagerWASM;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_error::FlowyResult;
use lib_dispatch::prelude::AFPluginDispatcher;
use lib_dispatch::runtime::AFPluginRuntime;
use std::rc::Rc;
use std::sync::Arc;

pub struct AppFlowyWASMCore {
  pub event_dispatcher: Arc<AFPluginDispatcher>,
  pub user_manager: Rc<UserManagerWASM>,
}

impl AppFlowyWASMCore {
  pub async fn new(device_id: &str) -> FlowyResult<Self> {
    let runtime = Arc::new(AFPluginRuntime::new().unwrap());
    let server_provider = Rc::new(ServerProviderWASM::new(device_id));

    let collab_builder = Arc::new(AppFlowyCollabBuilder::new(
      server_provider.clone(),
      device_id.to_string(),
    ));

    let user_manager = Rc::new(
      UserManagerWASM::new(
        device_id,
        server_provider.clone(),
        Arc::downgrade(&collab_builder),
      )
      .await?,
    );

    let event_dispatcher = Arc::new(AFPluginDispatcher::new(
      runtime,
      vec![af_user::event_map::init(Rc::downgrade(&user_manager))],
    ));
    Ok(Self {
      event_dispatcher,
      user_manager,
    })
  }
}
