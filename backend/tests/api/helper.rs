use backend::{
    application::{get_connection_pool, Application},
    config::{get_configuration, DatabaseSettings},
};

use flowy_document::{
    entities::doc::{CreateDocParams, Doc},
    prelude::*,
};
use flowy_user::{errors::UserError, prelude::*};
use flowy_workspace::prelude::{server::*, *};
use sqlx::{Connection, Executor, PgConnection, PgPool};
use uuid::Uuid;

pub struct TestServer {
    pub address: String,
    pub port: u16,
    pub pg_pool: PgPool,
    pub user_token: Option<String>,
    pub user_id: Option<String>,
}

impl TestServer {
    pub async fn new() -> Self {
        let mut server = spawn_server().await;
        let response = server.register_user().await;
        server.user_token = Some(response.token);
        server.user_id = Some(response.user_id);
        server
    }

    pub async fn sign_in(&self, params: SignInParams) -> Result<SignInResponse, UserError> {
        let url = format!("{}/api/auth", self.address);
        user_sign_in_request(params, &url).await
    }

    pub async fn sign_out(&self) {
        let url = format!("{}/api/auth", self.address);
        let _ = user_sign_out_request(self.user_token(), &url)
            .await
            .unwrap();
    }

    pub fn user_token(&self) -> &str {
        self.user_token
            .as_ref()
            .expect("must call register_user first ")
    }

    pub fn user_id(&self) -> &str {
        self.user_id
            .as_ref()
            .expect("must call register_user first ")
    }

    pub async fn get_user_profile(&self) -> UserProfile {
        let url = format!("{}/api/user", self.address);
        let user_profile = get_user_profile_request(self.user_token(), &url)
            .await
            .unwrap();
        user_profile
    }

    pub async fn update_user_profile(&self, params: UpdateUserParams) -> Result<(), UserError> {
        let url = format!("{}/api/user", self.address);
        update_user_profile_request(self.user_token(), params, &url).await
    }

    pub async fn create_workspace(&self, params: CreateWorkspaceParams) -> Workspace {
        let url = format!("{}/api/workspace", self.address);
        let workspace = create_workspace_request(self.user_token(), params, &url)
            .await
            .unwrap();
        workspace
    }

    pub async fn read_workspaces(&self, params: QueryWorkspaceParams) -> RepeatedWorkspace {
        let url = format!("{}/api/workspace", self.address);
        let workspaces = read_workspaces_request(self.user_token(), params, &url)
            .await
            .unwrap();
        workspaces
    }

    pub async fn update_workspace(&self, params: UpdateWorkspaceParams) {
        let url = format!("{}/api/workspace", self.address);
        update_workspace_request(self.user_token(), params, &url)
            .await
            .unwrap();
    }

    pub async fn delete_workspace(&self, params: DeleteWorkspaceParams) {
        let url = format!("{}/api/workspace", self.address);
        delete_workspace_request(self.user_token(), params, &url)
            .await
            .unwrap();
    }

    pub async fn create_app(&self, params: CreateAppParams) -> App {
        let url = format!("{}/api/app", self.address);
        let app = create_app_request(self.user_token(), params, &url)
            .await
            .unwrap();
        app
    }

    pub async fn read_app(&self, params: QueryAppParams) -> Option<App> {
        let url = format!("{}/api/app", self.address);
        let app = read_app_request(self.user_token(), params, &url)
            .await
            .unwrap();
        app
    }

    pub async fn update_app(&self, params: UpdateAppParams) {
        let url = format!("{}/api/app", self.address);
        update_app_request(self.user_token(), params, &url)
            .await
            .unwrap();
    }

    pub async fn delete_app(&self, params: DeleteAppParams) {
        let url = format!("{}/api/app", self.address);
        delete_app_request(self.user_token(), params, &url)
            .await
            .unwrap();
    }

    pub async fn create_view(&self, params: CreateViewParams) -> View {
        let url = format!("{}/api/view", self.address);
        let view = create_view_request(self.user_token(), params, &url)
            .await
            .unwrap();
        view
    }

    pub async fn read_view(&self, params: QueryViewParams) -> Option<View> {
        let url = format!("{}/api/view", self.address);
        let view = read_view_request(self.user_token(), params, &url)
            .await
            .unwrap();
        view
    }

    pub async fn update_view(&self, params: UpdateViewParams) {
        let url = format!("{}/api/view", self.address);
        update_view_request(self.user_token(), params, &url)
            .await
            .unwrap();
    }

    pub async fn delete_view(&self, params: DeleteViewParams) {
        let url = format!("{}/api/view", self.address);
        delete_view_request(self.user_token(), params, &url)
            .await
            .unwrap();
    }

    pub async fn create_doc(&self, params: CreateDocParams) {
        let url = format!("{}/api/doc", self.address);
        let _ = create_doc_request(self.user_token(), params, &url)
            .await
            .unwrap();
    }

    pub(crate) async fn register_user(&self) -> SignUpResponse {
        let params = SignUpParams {
            email: "annie@appflowy.io".to_string(),
            name: "annie".to_string(),
            password: "HelloAppFlowy123!".to_string(),
        };

        self.register(params).await
    }

    pub(crate) async fn register(&self, params: SignUpParams) -> SignUpResponse {
        let url = format!("{}/api/register", self.address);
        let response = user_sign_up_request(params, &url).await.unwrap();
        response
    }
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
    let application = Application::build(configuration.clone())
        .await
        .expect("Failed to build application.");
    let application_port = application.port();

    let _ = tokio::spawn(async {
        let _ = application.run_until_stopped();
        // drop_test_database(database_name).await;
    });

    TestServer {
        address: format!("http://localhost:{}", application_port),
        port: application_port,
        pg_pool: get_connection_pool(&configuration.database)
            .await
            .expect("Failed to connect to the database"),
        user_token: None,
        user_id: None,
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

pub(crate) async fn create_test_workspace(server: &TestServer) -> Workspace {
    let params = CreateWorkspaceParams {
        name: "My first workspace".to_string(),
        desc: "This is my first workspace".to_string(),
    };

    let workspace = server.create_workspace(params).await;
    workspace
}

pub(crate) async fn create_test_app(server: &TestServer, workspace_id: &str) -> App {
    let params = CreateAppParams {
        workspace_id: workspace_id.to_owned(),
        name: "My first app".to_string(),
        desc: "This is my first app".to_string(),
        color_style: ColorStyle::default(),
    };

    let app = server.create_app(params).await;
    app
}

pub(crate) async fn create_test_view(application: &TestServer, app_id: &str) -> View {
    let params = CreateViewParams {
        belong_to_id: app_id.to_string(),
        name: "My first view".to_string(),
        desc: "This is my first view".to_string(),
        thumbnail: "http://1.png".to_string(),
        view_type: ViewType::Doc,
    };
    let app = application.create_view(params).await;
    app
}

pub(crate) async fn create_test_doc(server: &TestServer, view_id: &str, data: &str) -> Doc {
    let params = CreateDocParams {
        id: view_id.to_string(),
        data: data.to_string(),
    };
    let doc = Doc {
        id: params.id.clone(),
        data: params.data.clone(),
    };
    let _ = server.create_doc(params).await;
    doc
}

pub struct WorkspaceTest {
    pub server: TestServer,
    pub workspace: Workspace,
}

impl WorkspaceTest {
    pub async fn new() -> Self {
        let server = TestServer::new().await;
        let workspace = create_test_workspace(&server).await;
        Self { server, workspace }
    }

    pub async fn create_app(&self) -> App {
        create_test_app(&self.server, &self.workspace.id).await
    }
}

pub struct AppTest {
    pub server: TestServer,
    pub workspace: Workspace,
    pub app: App,
}

impl AppTest {
    pub async fn new() -> Self {
        let server = TestServer::new().await;
        let workspace = create_test_workspace(&server).await;
        let app = create_test_app(&server, &workspace.id).await;
        Self {
            server,
            workspace,
            app,
        }
    }
}

pub struct ViewTest {
    pub server: TestServer,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
}

impl ViewTest {
    pub async fn new() -> Self {
        let server = TestServer::new().await;
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

pub struct DocTest {
    pub server: TestServer,
    pub workspace: Workspace,
    pub app: App,
    pub view: View,
    pub doc: Doc,
}

impl DocTest {
    pub async fn new() -> Self {
        let server = TestServer::new().await;
        let workspace = create_test_workspace(&server).await;
        let app = create_test_app(&server, &workspace.id).await;
        let view = create_test_view(&server, &app.id).await;
        let doc = create_test_doc(&server, &view.id, "").await;
        Self {
            server,
            workspace,
            app,
            view,
            doc,
        }
    }
}
