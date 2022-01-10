use backend_service::configuration::ClientServerConfiguration;
use flowy_core::{
    errors::FlowyError,
    module::{CoreCloudService, WorkspaceDatabase, WorkspaceUser},
    prelude::{
        App,
        AppId,
        CreateAppParams,
        CreateViewParams,
        CreateWorkspaceParams,
        RepeatedTrash,
        RepeatedTrashId,
        RepeatedViewId,
        RepeatedWorkspace,
        UpdateAppParams,
        UpdateViewParams,
        UpdateWorkspaceParams,
        View,
        ViewId,
        Workspace,
        WorkspaceId,
    },
};
use flowy_database::ConnectionPool;
use flowy_net::cloud::core::{CoreHttpCloudService, CoreLocalCloudService};
use flowy_user::services::user::UserSession;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub struct CoreDepsResolver();
impl CoreDepsResolver {
    pub fn resolve(
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
    ) -> (
        Arc<dyn WorkspaceUser>,
        Arc<dyn WorkspaceDatabase>,
        Arc<dyn CoreCloudService>,
    ) {
        let user: Arc<dyn WorkspaceUser> = Arc::new(WorkspaceUserImpl(user_session.clone()));
        let database: Arc<dyn WorkspaceDatabase> = Arc::new(WorkspaceDatabaseImpl(user_session));
        let cloud_service = make_core_cloud_service(server_config);
        (user, database, cloud_service)
    }
}

struct WorkspaceDatabaseImpl(Arc<UserSession>);
impl WorkspaceDatabase for WorkspaceDatabaseImpl {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
        self.0.db_pool().map_err(|e| FlowyError::internal().context(e))
    }
}

struct WorkspaceUserImpl(Arc<UserSession>);
impl WorkspaceUser for WorkspaceUserImpl {
    fn user_id(&self) -> Result<String, FlowyError> { self.0.user_id().map_err(|e| FlowyError::internal().context(e)) }

    fn token(&self) -> Result<String, FlowyError> { self.0.token().map_err(|e| FlowyError::internal().context(e)) }
}

fn make_core_cloud_service(config: &ClientServerConfiguration) -> Arc<dyn CoreCloudService> {
    if cfg!(feature = "http_server") {
        Arc::new(CoreHttpCloudServiceAdaptor::new(config))
    } else {
        Arc::new(CoreLocalCloudServiceAdaptor::new(config))
    }
}

struct CoreHttpCloudServiceAdaptor(CoreHttpCloudService);
impl CoreHttpCloudServiceAdaptor {
    fn new(config: &ClientServerConfiguration) -> Self { Self(CoreHttpCloudService::new(config.clone())) }
}
impl CoreCloudService for CoreHttpCloudServiceAdaptor {
    fn init(&self) {
        // let mut rx = BACKEND_API_MIDDLEWARE.invalid_token_subscribe();
        // tokio::spawn(async move {
        //     while let Ok(invalid_token) = rx.recv().await {
        //         let error = FlowyError::new(ErrorCode::UserUnauthorized, "");
        //         send_dart_notification(&invalid_token,
        // WorkspaceNotification::UserUnauthorized)             .error(error)
        //             .send()
        //     }
        // });
        self.0.init()
    }

    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, FlowyError> {
        self.0.create_workspace(token, params)
    }

    fn read_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<RepeatedWorkspace, FlowyError> {
        self.0.read_workspace(token, params)
    }

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError> {
        self.0.update_workspace(token, params)
    }

    fn delete_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<(), FlowyError> {
        self.0.delete_workspace(token, params)
    }

    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<View, FlowyError> {
        self.0.create_view(token, params)
    }

    fn read_view(&self, token: &str, params: ViewId) -> FutureResult<Option<View>, FlowyError> {
        self.0.read_view(token, params)
    }

    fn delete_view(&self, token: &str, params: RepeatedViewId) -> FutureResult<(), FlowyError> {
        self.0.delete_view(token, params)
    }

    fn update_view(&self, token: &str, params: UpdateViewParams) -> FutureResult<(), FlowyError> {
        self.0.update_view(token, params)
    }

    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<App, FlowyError> {
        self.0.create_app(token, params)
    }

    fn read_app(&self, token: &str, params: AppId) -> FutureResult<Option<App>, FlowyError> {
        self.0.read_app(token, params)
    }

    fn update_app(&self, token: &str, params: UpdateAppParams) -> FutureResult<(), FlowyError> {
        self.0.update_app(token, params)
    }

    fn delete_app(&self, token: &str, params: AppId) -> FutureResult<(), FlowyError> {
        self.0.delete_app(token, params)
    }

    fn create_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
        self.0.create_trash(token, params)
    }

    fn delete_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
        self.0.delete_trash(token, params)
    }

    fn read_trash(&self, token: &str) -> FutureResult<RepeatedTrash, FlowyError> { self.0.read_trash(token) }
}

struct CoreLocalCloudServiceAdaptor(CoreLocalCloudService);
impl CoreLocalCloudServiceAdaptor {
    fn new(config: &ClientServerConfiguration) -> Self { Self(CoreLocalCloudService::new(config)) }
}

impl CoreCloudService for CoreLocalCloudServiceAdaptor {
    fn init(&self) { self.0.init() }

    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, FlowyError> {
        self.0.create_workspace(token, params)
    }

    fn read_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<RepeatedWorkspace, FlowyError> {
        self.0.read_workspace(token, params)
    }

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError> {
        self.0.update_workspace(token, params)
    }

    fn delete_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<(), FlowyError> {
        self.0.delete_workspace(token, params)
    }

    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<View, FlowyError> {
        self.0.create_view(token, params)
    }

    fn read_view(&self, token: &str, params: ViewId) -> FutureResult<Option<View>, FlowyError> {
        self.0.read_view(token, params)
    }

    fn delete_view(&self, token: &str, params: RepeatedViewId) -> FutureResult<(), FlowyError> {
        self.0.delete_view(token, params)
    }

    fn update_view(&self, token: &str, params: UpdateViewParams) -> FutureResult<(), FlowyError> {
        self.0.update_view(token, params)
    }

    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<App, FlowyError> {
        self.0.create_app(token, params)
    }

    fn read_app(&self, token: &str, params: AppId) -> FutureResult<Option<App>, FlowyError> {
        self.0.read_app(token, params)
    }

    fn update_app(&self, token: &str, params: UpdateAppParams) -> FutureResult<(), FlowyError> {
        self.0.update_app(token, params)
    }

    fn delete_app(&self, token: &str, params: AppId) -> FutureResult<(), FlowyError> {
        self.0.delete_app(token, params)
    }

    fn create_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
        self.0.create_trash(token, params)
    }

    fn delete_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
        self.0.delete_trash(token, params)
    }

    fn read_trash(&self, token: &str) -> FutureResult<RepeatedTrash, FlowyError> { self.0.read_trash(token) }
}
