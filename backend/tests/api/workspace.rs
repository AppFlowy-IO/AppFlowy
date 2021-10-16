use crate::helper::*;
use flowy_workspace::entities::{
    app::{AppIdentifier, DeleteAppParams, UpdateAppParams},
    trash::{CreateTrashParams, TrashType},
    view::{UpdateViewParams, ViewIdentifier},
    workspace::{CreateWorkspaceParams, DeleteWorkspaceParams, QueryWorkspaceParams, UpdateWorkspaceParams},
};

#[actix_rt::test]
async fn workspace_create() {
    let test = WorkspaceTest::new().await;
    log::info!("{:?}", test.workspace);
}

#[actix_rt::test]
async fn workspace_read() {
    let test = WorkspaceTest::new().await;
    let read_params = QueryWorkspaceParams::new().workspace_id(&test.workspace.id);
    log::info!("{:?}", test.server.read_workspaces(read_params).await);
}

#[actix_rt::test]
async fn workspace_read_with_belongs() {
    let test = WorkspaceTest::new().await;

    let _ = test.create_app().await;
    let _ = test.create_app().await;
    let _ = test.create_app().await;

    let read_params = QueryWorkspaceParams::new().workspace_id(&test.workspace.id);
    let workspaces = test.server.read_workspaces(read_params).await;
    let workspace = workspaces.items.first().unwrap();
    assert_eq!(workspace.apps.len(), 3);
}

#[actix_rt::test]
async fn workspace_update() {
    let test = WorkspaceTest::new().await;
    let new_name = "rename workspace name";
    let new_desc = "rename workspace description";

    let update_params = UpdateWorkspaceParams {
        id: test.workspace.id.clone(),
        name: Some(new_name.to_string()),
        desc: Some(new_desc.to_string()),
    };
    test.server.update_workspace(update_params).await;
    let read_params = QueryWorkspaceParams::new().workspace_id(&test.workspace.id);
    let repeated_workspace = test.server.read_workspaces(read_params).await;

    let workspace = repeated_workspace.first().unwrap();
    assert_eq!(workspace.name, new_name);
    assert_eq!(workspace.desc, new_desc);
}

#[actix_rt::test]
async fn workspace_delete() {
    let test = WorkspaceTest::new().await;
    let delete_params = DeleteWorkspaceParams {
        workspace_id: test.workspace.id.clone(),
    };

    let _ = test.server.delete_workspace(delete_params).await;
    let read_params = QueryWorkspaceParams::new().workspace_id(&test.workspace.id);
    let repeated_workspace = test.server.read_workspaces(read_params).await;
    assert_eq!(repeated_workspace.len(), 0);
}

#[actix_rt::test]
async fn app_create() {
    let test = AppTest::new().await;
    log::info!("{:?}", test.app);
}

#[actix_rt::test]
async fn app_read() {
    let test = AppTest::new().await;
    let read_params = AppIdentifier::new(&test.app.id);
    assert_eq!(test.server.read_app(read_params).await.is_some(), true);
}

#[actix_rt::test]
async fn app_read_with_belongs() {
    let test = AppTest::new().await;

    let _ = create_test_view(&test.server, &test.app.id).await;
    let _ = create_test_view(&test.server, &test.app.id).await;

    let read_params = AppIdentifier::new(&test.app.id);
    let app = test.server.read_app(read_params).await.unwrap();
    assert_eq!(app.belongings.len(), 2);
}

#[actix_rt::test]
async fn app_read_with_belongs_in_trash() {
    let test = AppTest::new().await;

    let _ = create_test_view(&test.server, &test.app.id).await;
    let view = create_test_view(&test.server, &test.app.id).await;

    let params = CreateTrashParams {
        id: view.id.clone(),
        ty: TrashType::View,
    };
    test.server.create_trash(params).await;

    let read_params = AppIdentifier::new(&test.app.id);
    let app = test.server.read_app(read_params).await.unwrap();
    assert_eq!(app.belongings.len(), 1);
}

#[actix_rt::test]
async fn app_update() {
    let test = AppTest::new().await;

    let new_name = "flowy";

    let update_params = UpdateAppParams::new(&test.app.id).name(new_name);
    test.server.update_app(update_params).await;

    let read_params = AppIdentifier::new(&test.app.id);
    let app = test.server.read_app(read_params).await.unwrap();
    assert_eq!(&app.name, new_name);
}

#[actix_rt::test]
async fn app_delete() {
    let test = AppTest::new().await;

    let delete_params = DeleteAppParams {
        app_id: test.app.id.clone(),
    };
    test.server.delete_app(delete_params).await;
    let read_params = AppIdentifier::new(&test.app.id);
    assert_eq!(test.server.read_app(read_params).await.is_none(), true);
}

#[actix_rt::test]
async fn view_create() {
    let test = ViewTest::new().await;
    log::info!("{:?}", test.view);
}

#[actix_rt::test]
async fn view_update() {
    let test = ViewTest::new().await;
    let new_name = "name view name";

    // update
    let update_params = UpdateViewParams::new(&test.view.id).name(new_name);
    test.server.update_view(update_params).await;

    // read
    let read_params = ViewIdentifier::new(&test.view.id);
    let view = test.server.read_view(read_params).await.unwrap();
    assert_eq!(&view.name, new_name);
}

#[actix_rt::test]
async fn view_delete() {
    let test = ViewTest::new().await;

    // delete
    let params = CreateTrashParams {
        id: test.view.id.clone(),
        ty: TrashType::View,
    };
    test.server.create_trash(params).await;

    // read
    let read_params = ViewIdentifier::new(&test.view.id);
    assert_eq!(test.server.read_view(read_params).await.is_none(), true);
}

#[actix_rt::test]
async fn workspace_list_read() {
    let mut server = spawn_user_server().await;
    let token = server.register_user().await.token;
    server.user_token = Some(token);
    for i in 0..3 {
        let params = CreateWorkspaceParams {
            name: format!("{} workspace", i),
            desc: format!("This is my {} workspace", i),
        };
        let _ = server.create_workspace(params).await;
    }

    let read_params = QueryWorkspaceParams::new();
    let workspaces = server.read_workspaces(read_params).await;
    assert_eq!(workspaces.len(), 4);
}
