use backend::{
    application::{get_connection_pool, Application},
    config::{get_configuration, DatabaseSettings},
    context::AppContext,
};

use backend::application::init_app_context;
use flowy_document::{
    entities::doc::{Doc, DocIdentifier},
    prelude::*,
};
use flowy_user::{errors::UserError, prelude::*};
use flowy_workspace::prelude::{server::*, *};
use sqlx::{Connection, Executor, PgConnection, PgPool};
use uuid::Uuid;

pub struct TestUserServer {
    pub host: String,
    pub port: u16,
    pub pg_pool: PgPool,
    pub user_token: Option<String>,
    pub user_id: Option<String>,
}

impl TestUserServer {
    pub async fn new() -> Self {
        let mut server: TestUserServer = spawn_server().await.into();
        let response = server.register_user().await;
        server.user_token = Some(response.token);
        server.user_id = Some(response.user_id);
        server
    }

    pub async fn sign_in(&self, params: SignInParams) -> Result<SignInResponse, UserError> {
        let url = format!("{}/api/auth", self.http_addr());
        user_sign_in_request(params, &url).await
    }

    pub async fn sign_out(&self) {
        let url = format!("{}/api/auth", self.http_addr());
        let _ = user_sign_out_request(self.user_token(), &url).await.unwrap();
    }

    pub fn user_token(&self) -> &str { self.user_token.as_ref().expect("must call register_user first ") }

    pub fn user_id(&self) -> &str { self.user_id.as_ref().expect("must call register_user first ") }

    pub async fn get_user_profile(&self) -> UserProfile {
        let url = format!("{}/api/user", self.http_addr());
        let user_profile = get_user_profile_request(self.user_token(), &url).await.unwrap();
        user_profile
    }

    pub async fn update_user_profile(&self, params: UpdateUserParams) -> Result<(), UserError> {
        let url = format!("{}/api/user", self.http_addr());
        update_user_profile_request(self.user_token(), params, &url).await
    }

    pub async fn create_workspace(&self, params: CreateWorkspaceParams) -> Workspace {
        let url = format!("{}/api/workspace", self.http_addr());
        let workspace = create_workspace_request(self.user_token(), params, &url).await.unwrap();
        workspace
    }

    pub async fn read_workspaces(&self, params: QueryWorkspaceParams) -> RepeatedWorkspace {
        let url = format!("{}/api/workspace", self.http_addr());
        let workspaces = read_workspaces_request(self.user_token(), params, &url).await.unwrap();
        workspaces
    }

    pub async fn update_workspace(&self, params: UpdateWorkspaceParams) {
        let url = format!("{}/api/workspace", self.http_addr());
        update_workspace_request(self.user_token(), params, &url).await.unwrap();
    }

    pub async fn delete_workspace(&self, params: DeleteWorkspaceParams) {
        let url = format!("{}/api/workspace", self.http_addr());
        delete_workspace_request(self.user_token(), params, &url).await.unwrap();
    }

    pub async fn create_app(&self, params: CreateAppParams) -> App {
        let url = format!("{}/api/app", self.http_addr());
        let app = create_app_request(self.user_token(), params, &url).await.unwrap();
        app
    }

    pub async fn read_app(&self, params: AppIdentifier) -> Option<App> {
        let url = format!("{}/api/app", self.http_addr());
        let app = read_app_request(self.user_token(), params, &url).await.unwrap();
        app
    }

    pub async fn update_app(&self, params: UpdateAppParams) {
        let url = format!("{}/api/app", self.http_addr());
        update_app_request(self.user_token(), params, &url).await.unwrap();
    }

    pub async fn delete_app(&self, params: DeleteAppParams) {
        let url = format!("{}/api/app", self.http_addr());
        delete_app_request(self.user_token(), params, &url).await.unwrap();
    }

    pub async fn create_view(&self, params: CreateViewParams) -> View {
        let url = format!("{}/api/view", self.http_addr());
        let view = create_view_request(self.user_token(), params, &url).await.unwrap();
        view
    }

    pub async fn read_view(&self, params: ViewIdentifier) -> Option<View> {
        let url = format!("{}/api/view", self.http_addr());
        let view = read_view_request(self.user_token(), params, &url).await.unwrap();
        view
    }

    pub async fn update_view(&self, params: UpdateViewParams) {
        let url = format!("{}/api/view", self.http_addr());
        update_view_request(self.user_token(), params, &url).await.unwrap();
    }

    pub async fn delete_view(&self, params: DeleteViewParams) {
        let url = format!("{}/api/view", self.http_addr());
        delete_view_request(self.user_token(), params, &url).await.unwrap();
    }

    pub async fn create_view_trash(&self, view_id: &str) {
        let identifier = TrashIdentifier {
            id: view_id.to_string(),
            ty: TrashType::View,
        };
        let url = format!("{}/api/trash", self.http_addr());
        create_trash_request(self.user_token(), vec![identifier].into(), &url)
            .await
            .unwrap();
    }

    pub async fn delete_view_trash(&self, trash_id: &str) {
        let url = format!("{}/api/trash", self.http_addr());

        let identifier = TrashIdentifier {
            id: trash_id.to_string(),
            ty: TrashType::View,
        };
        delete_trash_request(self.user_token(), vec![identifier].into(), &url)
            .await
            .unwrap();
    }

    pub async fn read_trash(&self) -> RepeatedTrash {
        let url = format!("{}/api/trash", self.http_addr());
        read_trash_request(self.user_token(), &url).await.unwrap()
    }

    pub async fn read_doc(&self, params: DocIdentifier) -> Option<Doc> {
        let url = format!("{}/api/doc", self.http_addr());
        let doc = read_doc_request(self.user_token(), params, &url).await.unwrap();
        doc
    }

    pub async fn register_user(&self) -> SignUpResponse {
        let params = SignUpParams {
            email: "annie@appflowy.io".to_string(),
            name: "annie".to_string(),
            password: "HelloAppFlowy123!".to_string(),
        };

        self.register(params).await
    }

    pub async fn register(&self, params: SignUpParams) -> SignUpResponse {
        let url = format!("{}/api/register", self.http_addr());
        let response = user_sign_up_request(params, &url).await.unwrap();
        response
    }

    pub fn http_addr(&self) -> String { format!("http://{}", self.host) }

    pub fn ws_addr(&self) -> String { format!("ws://{}/ws/{}", self.host, self.user_token.as_ref().unwrap()) }
}

impl std::convert::From<TestServer> for TestUserServer {
    fn from(server: TestServer) -> Self {
        TestUserServer {
            host: server.host,
            port: server.port,
            pg_pool: server.pg_pool,
            user_token: None,
            user_id: None,
        }
    }
}

pub async fn spawn_user_server() -> TestUserServer {
    let server: TestUserServer = spawn_server().await.into();
    server
}

pub struct TestServer {
    pub host: String,
    pub port: u16,
    pub pg_pool: PgPool,
    pub app_ctx: AppContext,
}

pub async fn spawn_server() -> TestServer {
    let database_name = format!("{}", Uuid::new_v4().to_string());
    let configuration = {
        let mut c = get_configuration().expect("Failed to read configuration.");
        c.database.database_name = database_name.clone();
        // Use a random OS port
        c.application.port = 0;
        c
    };

    let _ = configure_database(&configuration.database).await;
    let app_ctx = init_app_context(&configuration).await;
    let application = Application::build(configuration.clone(), app_ctx.clone())
        .await
        .expect("Failed to build application.");
    let application_port = application.port();

    let _ = tokio::spawn(async {
        let _ = application.run_until_stopped();
        // drop_test_database(database_name).await;
    });

    TestServer {
        host: format!("localhost:{}", application_port),
        port: application_port,
        pg_pool: get_connection_pool(&configuration.database)
            .await
            .expect("Failed to connect to the database"),
        app_ctx,
    }
}

async fn configure_database(config: &DatabaseSettings) -> PgPool {
    // Create database
    let mut connection = PgConnection::connect_with(&config.without_db())
        .await
        .expect("Failed to connect to Postgres");
    connection
        .execute(&*format!(r#"CREATE DATABASE "{}";"#, config.database_name))
        .await
        .expect("Failed to create database.");

    // Migrate database
    let connection_pool = PgPool::connect_with(config.with_db())
        .await
        .expect("Failed to connect to Postgres.");

    sqlx::migrate!("./migrations")
        .run(&connection_pool)
        .await
        .expect("Failed to migrate the database");

    connection_pool
}

#[allow(dead_code)]
async fn drop_test_database(database_name: String) {
    // https://stackoverflow.com/questions/36502401/postgres-drop-database-error-pq-cannot-drop-the-currently-open-database?rq=1
    let configuration = {
        let mut c = get_configuration().expect("Failed to read configuration.");
        c.database.database_name = "flowy".to_owned();
        c.application.port = 0;
        c
    };

    let mut connection = PgConnection::connect_with(&configuration.database.without_db())
        .await
        .expect("Failed to connect to Postgres");

    connection
        .execute(&*format!(r#"Drop DATABASE "{}";"#, database_name))
        .await
        .expect("Failed to drop database.");
}

pub async fn create_test_workspace(server: &TestUserServer) -> Workspace {
    let params = CreateWorkspaceParams {
        name: "My first workspace".to_string(),
        desc: "This is my first workspace".to_string(),
    };

    let workspace = server.create_workspace(params).await;
    workspace
}

pub async fn create_test_app(server: &TestUserServer, workspace_id: &str) -> App {
    let params = CreateAppParams {
        workspace_id: workspace_id.to_owned(),
        name: "My first app".to_string(),
        desc: "This is my first app".to_string(),
        color_style: ColorStyle::default(),
    };

    let app = server.create_app(params).await;
    app
}

pub async fn create_test_view(application: &TestUserServer, app_id: &str) -> View {
    let name = "My first view".to_string();
    let desc = "This is my first view".to_string();
    let thumbnail = "http://1.png".to_string();

    let params = CreateViewParams::new(app_id.to_owned(), name, desc, ViewType::Doc, thumbnail);
    let app = application.create_view(params).await;
    app
}

pub struct WorkspaceTest {
    pub server: TestUserServer,
    pub workspace: Workspace,
}

impl WorkspaceTest {
    pub async fn new() -> Self {
        let server = TestUserServer::new().await;
        let workspace = create_test_workspace(&server).await;
        Self { server, workspace }
    }

    pub async fn create_app(&self) -> App { create_test_app(&self.server, &self.workspace.id).await }
}

pub struct AppTest {
    pub server: TestUserServer,
    pub workspace: Workspace,
    pub app: App,
}

impl AppTest {
    pub async fn new() -> Self {
        let server = TestUserServer::new().await;
        let workspace = create_test_workspace(&server).await;
        let app = create_test_app(&server, &workspace.id).await;
        Self { server, workspace, app }
    }
}

pub struct ViewTest {
    pub server: TestUserServer,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
}

impl ViewTest {
    pub async fn new() -> Self {
        let server = TestUserServer::new().await;
        let workspace = create_test_workspace(&server).await;
        let app = create_test_app(&server, &workspace.id).await;
        let view = create_test_view(&server, &app.id).await;
        Self {
            server,
            workspace,
            app,
            view,
        }
    }
}
