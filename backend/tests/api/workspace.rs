use crate::helper::*;
use flowy_workspace_infra::entities::{
    app::{AppIdentifier, UpdateAppParams},
    trash::{TrashIdentifier, TrashIdentifiers, TrashType},
    view::{UpdateViewParams, ViewIdentifier},
    workspace::{CreateWorkspaceParams, UpdateWorkspaceParams, WorkspaceIdentifier},
};

#[actix_rt::test]
async fn workspace_create() {
    let test = WorkspaceTest::new().await;
    tracing::info!("{:?}", test.workspace);
}

#[actix_rt::test]
async fn workspace_read() {
    let test = WorkspaceTest::new().await;
    let read_params = WorkspaceIdentifier::new(Some(test.workspace.id.clone()));
    let repeated_workspace = test.server.read_workspaces(read_params).await;
    tracing::info!("{:?}", repeated_workspace);
}

#[actix_rt::test]
async fn workspace_read_with_belongs() {
    let test = WorkspaceTest::new().await;

    let _ = test.create_app().await;
    let _ = test.create_app().await;
    let _ = test.create_app().await;

    let read_params = WorkspaceIdentifier::new(Some(test.workspace.id.clone()));
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
    let read_params = WorkspaceIdentifier::new(Some(test.workspace.id.clone()));
    let repeated_workspace = test.server.read_workspaces(read_params).await;

    let workspace = repeated_workspace.first().unwrap();
    assert_eq!(workspace.name, new_name);
    assert_eq!(workspace.desc, new_desc);
}

#[actix_rt::test]
async fn workspace_delete() {
    let test = WorkspaceTest::new().await;
    let delete_params = WorkspaceIdentifier {
        workspace_id: test.workspace.id.clone(),
    };

    let _ = test.server.delete_workspace(delete_params).await;
    let read_params = WorkspaceIdentifier::new(Some(test.workspace.id.clone()));
    let repeated_workspace = test.server.read_workspaces(read_params).await;
    assert_eq!(repeated_workspace.len(), 0);
}

#[actix_rt::test]
async fn app_create() {
    let test = AppTest::new().await;
    tracing::info!("{:?}", test.app);
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

    test.server.create_view_trash(&view.id).await;

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

    let delete_params = AppIdentifier {
        app_id: test.app.id.clone(),
    };
    test.server.delete_app(delete_params).await;
    let read_params = AppIdentifier::new(&test.app.id);
    assert_eq!(test.server.read_app(read_params).await.is_none(), true);
}

#[actix_rt::test]
async fn view_create() {
    let test = ViewTest::new().await;
    tracing::info!("{:?}", test.view);
}

#[actix_rt::test]
async fn view_update() {
    let test = ViewTest::new().await;
    let new_name = "name view name";

    // update
    let update_params = UpdateViewParams::new(&test.view.id).name(new_name);
    test.server.update_view(update_params).await;

    // read
    let read_params: ViewIdentifier = test.view.id.clone().into();
    let view = test.server.read_view(read_params).await.unwrap();
    assert_eq!(&view.name, new_name);
}

#[actix_rt::test]
async fn view_delete() {
    let test = ViewTest::new().await;
    test.server.create_view_trash(&test.view.id).await;

    let trash_ids = test
        .server
        .read_trash()
        .await
        .items
        .into_iter()
        .map(|item| item.id)
        .collect::<Vec<String>>();
    // read
    let read_params: ViewIdentifier = test.view.id.clone().into();

    // the view can't read from the server. it should be in the trash
    assert_eq!(test.server.read_view(read_params).await.is_none(), true);
    assert_eq!(trash_ids.contains(&test.view.id), true);
}

#[actix_rt::test]
async fn trash_delete() {
    let test = ViewTest::new().await;
    test.server.create_view_trash(&test.view.id).await;

    let identifier = TrashIdentifier {
        id: test.view.id.clone(),
        ty: TrashType::View,
    };
    test.server.delete_view_trash(vec![identifier].into()).await;

    assert_eq!(test.server.read_trash().await.is_empty(), true);
}

#[actix_rt::test]
async fn trash_delete_all() {
    let test = ViewTest::new().await;
    test.server.create_view_trash(&test.view.id).await;

    test.server.delete_view_trash(TrashIdentifiers::all()).await;
    assert_eq!(test.server.read_trash().await.is_empty(), true);
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

    let read_params = WorkspaceIdentifier::new(None);
    let workspaces = server.read_workspaces(read_params).await;
    assert_eq!(workspaces.len(), 4);
}
