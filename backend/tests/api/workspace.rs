use crate::helper::{spawn_app, TestApp};
use flowy_workspace::entities::workspace::{CreateWorkspaceParams, QueryWorkspaceParams};

#[actix_rt::test]
async fn workspace_create() {
    let app = spawn_app().await;

    let params = CreateWorkspaceParams {
        name: "My first workspace".to_string(),
        desc: "This is my first workspace".to_string(),
        user_id: None,
    };

    let workspace = app.create_workspace(params).await;
    log::info!("{:?}", workspace);
}

#[actix_rt::test]
async fn workspace_read() {
    let app = spawn_app().await;
    let params = CreateWorkspaceParams {
        name: "My first workspace".to_string(),
        desc: "This is my first workspace".to_string(),
        user_id: None,
    };
    let workspace_1 = app.create_workspace(params).await;

    let read_params = QueryWorkspaceParams {
        workspace_id: workspace_1.id.clone(),
        read_apps: false,
    };
    let workspace_2 = app.read_workspace(read_params).await;

    log::info!("{:?}", workspace_2);
}
