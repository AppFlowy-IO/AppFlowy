use crate::deps_resolve::document_deps::DocumentDepsResolver;
use crate::deps_resolve::folder_deps::FolderDepsResolver;
use crate::integrate::server::ServerProviderWASM;
use af_persistence::store::AppFlowyWASMStore;
use af_user::authenticate_user::AuthenticateUser;
use af_user::manager::UserManager;
use collab_integrate::collab_builder::{AppFlowyCollabBuilder, WorkspaceCollabIntegrate};
use flowy_document::manager::DocumentManager;
use flowy_error::FlowyResult;
use flowy_folder::manager::FolderManager;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_storage::ObjectStorageService;
use lib_dispatch::prelude::AFPluginDispatcher;
use lib_dispatch::runtime::AFPluginRuntime;
use std::rc::Rc;
use std::sync::Arc;

pub struct AppFlowyWASMCore {
  pub collab_builder: Arc<AppFlowyCollabBuilder>,
  pub event_dispatcher: Rc<AFPluginDispatcher>,
  pub user_manager: Rc<UserManager>,
  pub folder_manager: Rc<FolderManager>,
  pub document_manager: Rc<DocumentManager>,
}

impl AppFlowyWASMCore {
  pub async fn new(device_id: &str, cloud_config: AFCloudConfiguration) -> FlowyResult<Self> {
    let runtime = Arc::new(AFPluginRuntime::new().unwrap());
    let server_provider = Rc::new(ServerProviderWASM::new(device_id, cloud_config));
    let store = Rc::new(AppFlowyWASMStore::new().await?);
    let auth_user = Rc::new(AuthenticateUser::new(store.clone()).await?);
    let collab_builder = Arc::new(AppFlowyCollabBuilder::new(
      device_id.to_string(),
      server_provider.clone(),
      WorkspaceCollabIntegrateImpl(auth_user.clone()),
    ));

    let document_manager = DocumentDepsResolver::resolve(
      Rc::downgrade(&auth_user),
      collab_builder.clone(),
      server_provider.clone(),
      Rc::downgrade(&(server_provider.clone() as Rc<dyn ObjectStorageService>)),
    )
    .await;

    let folder_manager = FolderDepsResolver::resolve(
      Rc::downgrade(&auth_user),
      document_manager.clone(),
      collab_builder.clone(),
      server_provider.clone(),
    )
    .await;

    let user_manager = Rc::new(
      UserManager::new(
        device_id,
        store,
        server_provider.clone(),
        auth_user,
        Arc::downgrade(&collab_builder),
      )
      .await?,
    );

    let event_dispatcher = Rc::new(AFPluginDispatcher::new(
      runtime,
      vec![af_user::event_map::init(Rc::downgrade(&user_manager))],
    ));
    Ok(Self {
      collab_builder,
      event_dispatcher,
      user_manager,
      folder_manager,
      document_manager,
    })
  }
}

struct WorkspaceCollabIntegrateImpl(Rc<AuthenticateUser>);
impl WorkspaceCollabIntegrate for WorkspaceCollabIntegrateImpl {
  fn workspace_id(&self) -> Result<String, anyhow::Error> {
    let workspace_id = self.0.workspace_id()?;
    Ok(workspace_id)
  }

  fn device_id(&self) -> String {
    "fake device id".to_string()
  }
}
