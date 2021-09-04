use backend::{
    application::{get_connection_pool, Application},
    config::{get_configuration, DatabaseSettings},
};

use flowy_user::{errors::UserError, prelude::*};
use flowy_workspace::prelude::{server::*, *};
use sqlx::{Connection, Executor, PgConnection, PgPool};
use uuid::Uuid;

pub struct TestApp {
    pub address: String,
    pub port: u16,
    pub pg_pool: PgPool,
}

impl TestApp {
    pub async fn register_user(&self, params: SignUpParams) -> SignUpResponse {
        let url = format!("{}/api/register", self.address);
        let resp = user_sign_up_request(params, &url).await.unwrap();
        resp
    }

    pub async fn sign_in(&self, params: SignInParams) -> Result<SignInResponse, UserError> {
        let url = format!("{}/api/auth", self.address);
        user_sign_in_request(params, &url).await
    }

    pub async fn sign_out(&self, token: &str) {
        let url = format!("{}/api/auth", self.address);
        let _ = user_sign_out_request(token, &url).await.unwrap();
    }

    pub async fn get_user_profile(&self, token: &str) -> UserProfile {
        let url = format!("{}/api/user", self.address);
        let user_profile = get_user_profile_request(token, &url).await.unwrap();
        user_profile
    }

    pub async fn update_user_profile(
        &self,
        token: &str,
        params: UpdateUserParams,
    ) -> Result<(), UserError> {
        let url = format!("{}/api/user", self.address);
        update_user_profile_request(token, params, &url).await
    }

    pub async fn create_workspace(&self, params: CreateWorkspaceParams, token: &str) -> Workspace {
        let url = format!("{}/api/workspace", self.address);
        let workspace = create_workspace_request(token, params, &url).await.unwrap();
        workspace
    }

    pub async fn read_workspaces(
        &self,
        params: QueryWorkspaceParams,
        token: &str,
    ) -> RepeatedWorkspace {
        let url = format!("{}/api/workspace", self.address);
        let workspaces = read_workspaces_request(token, params, &url).await.unwrap();
        workspaces
    }

    pub async fn update_workspace(&self, params: UpdateWorkspaceParams, token: &str) {
        let url = format!("{}/api/workspace", self.address);
        update_workspace_request(token, params, &url).await.unwrap();
    }

    pub async fn delete_workspace(&self, params: DeleteWorkspaceParams, token: &str) {
        let url = format!("{}/api/workspace", self.address);
        delete_workspace_request(token, params, &url).await.unwrap();
    }

    pub async fn create_app(&self, params: CreateAppParams, token: &str) -> App {
        let url = format!("{}/api/app", self.address);
        let app = create_app_request(token, params, &url).await.unwrap();
        app
    }

    pub async fn read_app(&self, params: QueryAppParams, token: &str) -> Option<App> {
        let url = format!("{}/api/app", self.address);
        let app = read_app_request(token, params, &url).await.unwrap();
        app
    }

    pub async fn update_app(&self, params: UpdateAppParams, token: &str) {
        let url = format!("{}/api/app", self.address);
        update_app_request(token, params, &url).await.unwrap();
    }

    pub async fn delete_app(&self, params: DeleteAppParams, token: &str) {
        let url = format!("{}/api/app", self.address);
        delete_app_request(token, params, &url).await.unwrap();
    }

    pub async fn create_view(&self, params: CreateViewParams, token: &str) -> View {
        let url = format!("{}/api/view", self.address);
        let view = create_view_request(token, params, &url).await.unwrap();
        view
    }

    pub async fn read_view(&self, params: QueryViewParams, token: &str) -> Option<View> {
        let url = format!("{}/api/view", self.address);
        let view = read_view_request(token, params, &url).await.unwrap();
        view
    }

    pub async fn update_view(&self, params: UpdateViewParams, token: &str) {
        let url = format!("{}/api/view", self.address);
        update_view_request(token, params, &url).await.unwrap();
    }

    pub async fn delete_view(&self, params: DeleteViewParams, token: &str) {
        let url = format!("{}/api/view", self.address);
        delete_view_request(token, params, &url).await.unwrap();
    }

    pub(crate) async fn register_test_user(&self) -> SignUpResponse {
        let params = SignUpParams {
            email: "annie@appflowy.io".to_string(),
            name: "annie".to_string(),
            password: "HelloAppFlowy123!".to_string(),
        };

        let response = self.register_user(params).await;
        response
    }
}

pub async fn spawn_app() -> TestApp {
    let configuration = {
        let mut c = get_configuration().expect("Failed to read configuration.");
        c.database.database_name = Uuid::new_v4().to_string();
        // Use a random OS port
        c.application.port = 0;
        c
    };

    let _ = configure_database(&configuration.database).await;
    let application = Application::build(configuration.clone())
        .await
        .expect("Failed to build application.");
    let application_port = application.port();

    let _ = tokio::spawn(application.run_until_stopped());

    TestApp {
        address: format!("http://localhost:{}", application_port),
        port: application_port,
        pg_pool: get_connection_pool(&configuration.database)
            .await
            .expect("Failed to connect to the database"),
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
