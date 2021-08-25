use crate::helper::{spawn_app, TestApp};
use flowy_workspace::entities::{
    app::{App, ColorStyle, CreateAppParams, DeleteAppParams, QueryAppParams, UpdateAppParams},
    workspace::{
        CreateWorkspaceParams,
        DeleteWorkspaceParams,
        QueryWorkspaceParams,
        UpdateWorkspaceParams,
        Workspace,
    },
};

#[actix_rt::test]
async fn workspace_create() {
    let app = spawn_app().await;
    let (workspace, _) = create_test_workspace(&app).await;
    log::info!("{:?}", workspace);
}

#[actix_rt::test]
async fn workspace_read() {
    let app = spawn_app().await;
    let (workspace_1, _) = create_test_workspace(&app).await;

    let read_params = QueryWorkspaceParams {
        workspace_id: workspace_1.id.clone(),
        read_apps: false,
    };

    log::info!("{:?}", app.read_workspace(read_params).await.unwrap());
}

#[actix_rt::test]
async fn workspace_update() {
    let app = spawn_app().await;
    let (workspace_1, _) = create_test_workspace(&app).await;
    let update_params = UpdateWorkspaceParams {
        id: workspace_1.id.clone(),
        name: Some("workspace 2".to_string()),
        desc: Some("rename workspace description".to_string()),
    };
    app.update_workspace(update_params).await;

    let read_params = QueryWorkspaceParams {
        workspace_id: workspace_1.id.clone(),
        read_apps: false,
    };
    let workspace_2 = app.read_workspace(read_params).await.unwrap();
    log::info!("{:?}", workspace_2);
}

#[actix_rt::test]
async fn workspace_delete() {
    let app = spawn_app().await;
    let (workspace, _) = create_test_workspace(&app).await;
    let delete_params = DeleteWorkspaceParams {
        workspace_id: workspace.id.clone(),
    };

    let _ = app.delete_workspace(delete_params).await;
    let read_params = QueryWorkspaceParams {
        workspace_id: workspace.id.clone(),
        read_apps: false,
    };
    assert_eq!(app.read_workspace(read_params).await.is_none(), true);
}

async fn create_test_workspace(app: &TestApp) -> (Workspace, String) {
    let response = app.register_test_user().await;

    let params = CreateWorkspaceParams {
        name: "My first workspace".to_string(),
        desc: "This is my first workspace".to_string(),
        user_id: response.uid.clone(),
    };
    let workspace = app.create_workspace(params).await;
    (workspace, response.uid)
}

#[actix_rt::test]
async fn app_create() {
    let application = spawn_app().await;
    let app = create_test_app(&application).await;
    log::info!("{:?}", app);
}

#[actix_rt::test]
async fn app_read() {
    let application = spawn_app().await;
    let app = create_test_app(&application).await;

    let read_params = QueryAppParams {
        app_id: app.id,
        read_belongings: false,
        is_trash: false,
    };

    log::info!("{:?}", application.read_app(read_params).await.unwrap());
}

#[actix_rt::test]
async fn app_update() {
    let application = spawn_app().await;
    let app = create_test_app(&application).await;

    let update_params = UpdateAppParams {
        app_id: app.id.clone(),
        workspace_id: None,
        name: Some("flowy".to_owned()),
        desc: None,
        color_style: None,
        is_trash: None,
    };
    application.update_app(update_params).await;

    let read_params = QueryAppParams {
        app_id: app.id,
        read_belongings: false,
        is_trash: false,
    };

    let app = application.read_app(read_params).await.unwrap();
    log::info!("{:?}", app);
}

#[actix_rt::test]
async fn app_delete() {
    let application = spawn_app().await;
    let app = create_test_app(&application).await;

    let delete_params = DeleteAppParams {
        app_id: app.id.clone(),
    };
    application.delete_app(delete_params).await;

    let read_params = QueryAppParams {
        app_id: app.id,
        read_belongings: false,
        is_trash: false,
    };

    assert_eq!(application.read_app(read_params).await.is_none(), true);
}

async fn create_test_app(app: &TestApp) -> App {
    let (workspace, user_id) = create_test_workspace(&app).await;

    let params = CreateAppParams {
        workspace_id: workspace.id,
        name: "My first app".to_string(),
        desc: "This is my first app".to_string(),
        color_style: ColorStyle::default(),
        user_id,
    };

    let app = app.create_app(params).await;
    app
}
