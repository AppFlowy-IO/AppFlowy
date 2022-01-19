use flowy_core::{
    entities::workspace::{CreateWorkspaceRequest, QueryWorkspaceRequest},
    event::WorkspaceEvent::*,
    prelude::*,
};
use flowy_test::{event_builder::*, helper::*, FlowySDKTest};

#[tokio::test]
async fn workspace_read_all() {
    let test = WorkspaceTest::new().await;
    let workspace = read_workspace(&test.sdk, QueryWorkspaceRequest::new(None)).await;
    assert_eq!(workspace.len(), 2);
}

#[tokio::test]
async fn workspace_read() {
    let test = WorkspaceTest::new().await;
    let request = QueryWorkspaceRequest::new(Some(test.workspace.id.clone()));
    let workspace_from_db = read_workspace(&test.sdk, request)
        .await
        .drain(..1)
        .collect::<Vec<Workspace>>()
        .pop()
        .unwrap();
    assert_eq!(test.workspace, workspace_from_db);
}

#[tokio::test]
async fn workspace_create_with_apps() {
    let test = WorkspaceTest::new().await;
    let app = create_app(&test.sdk, "App A", "AppFlowy GitHub Project", &test.workspace.id).await;
    let request = QueryWorkspaceRequest::new(Some(test.workspace.id.clone()));
    let workspace_from_db = read_workspace(&test.sdk, request)
        .await
        .drain(..1)
        .collect::<Vec<Workspace>>()
        .pop()
        .unwrap();
    assert_eq!(&app, workspace_from_db.apps.first_or_crash());
}

#[tokio::test]
async fn workspace_create_with_invalid_name() {
    for (name, code) in invalid_workspace_name_test_case() {
        let sdk = FlowySDKTest::default();
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };
        assert_eq!(
            CoreModuleEventBuilder::new(sdk)
                .event(CreateWorkspace)
                .request(request)
                .async_send()
                .await
                .error()
                .code,
            code.value()
        )
    }
}

#[tokio::test]
async fn workspace_update_with_invalid_name() {
    let sdk = FlowySDKTest::default();
    for (name, code) in invalid_workspace_name_test_case() {
        let request = CreateWorkspaceRequest {
            name,
            desc: "".to_owned(),
        };
        assert_eq!(
            CoreModuleEventBuilder::new(sdk.clone())
                .event(CreateWorkspace)
                .request(request)
                .async_send()
                .await
                .error()
                .code,
            code.value()
        )
    }
}

#[tokio::test]
#[should_panic]
async fn app_delete() {
    let test = AppTest::new().await;
    delete_app(&test.sdk, &test.app.id).await;
    let query = QueryAppRequest {
        app_ids: vec![test.app.id.clone()],
    };
    let _ = read_app(&test.sdk, query).await;
}

#[tokio::test]
async fn app_delete_then_putback() {
    let test = AppTest::new().await;
    delete_app(&test.sdk, &test.app.id).await;
    putback_trash(
        &test.sdk,
        TrashId {
            id: test.app.id.clone(),
            ty: TrashType::App,
        },
    )
    .await;

    let query = QueryAppRequest {
        app_ids: vec![test.app.id.clone()],
    };
    let app = read_app(&test.sdk, query).await;
    assert_eq!(&app, &test.app);
}

#[tokio::test]
async fn app_read() {
    let test = AppTest::new().await;
    let query = QueryAppRequest {
        app_ids: vec![test.app.id.clone()],
    };
    let app_from_db = read_app(&test.sdk, query).await;
    assert_eq!(app_from_db, test.app);
}

#[tokio::test]
async fn app_create_with_view() {
    let test = AppTest::new().await;
    let request_a = CreateViewRequest {
        belong_to_id: test.app.id.clone(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::Doc,
    };

    let request_b = CreateViewRequest {
        belong_to_id: test.app.id.clone(),
        name: "View B".to_string(),
        desc: "".to_string(),
        thumbnail: Some("http://1.png".to_string()),
        view_type: ViewType::Doc,
    };

    let view_a = create_view_with_request(&test.sdk, request_a).await;
    let view_b = create_view_with_request(&test.sdk, request_b).await;

    let query = QueryAppRequest {
        app_ids: vec![test.app.id.clone()],
    };
    let view_from_db = read_app(&test.sdk, query).await;

    assert_eq!(view_from_db.belongings[0], view_a);
    assert_eq!(view_from_db.belongings[1], view_b);
}

#[tokio::test]
#[should_panic]
async fn view_delete() {
    let test = FlowySDKTest::default();
    let _ = test.init_user().await;

    let test = ViewTest::new(&test).await;
    test.delete_views(vec![test.view.id.clone()]).await;
    let query = QueryViewRequest {
        view_ids: vec![test.view.id.clone()],
    };
    let _ = read_view(&test.sdk, query).await;
}

#[tokio::test]
async fn view_delete_then_putback() {
    let test = FlowySDKTest::default();
    let _ = test.init_user().await;

    let test = ViewTest::new(&test).await;
    test.delete_views(vec![test.view.id.clone()]).await;
    putback_trash(
        &test.sdk,
        TrashId {
            id: test.view.id.clone(),
            ty: TrashType::View,
        },
    )
    .await;

    let query = QueryViewRequest {
        view_ids: vec![test.view.id.clone()],
    };
    let view = read_view(&test.sdk, query).await;
    assert_eq!(&view, &test.view);
}

#[tokio::test]
async fn view_delete_all() {
    let test = FlowySDKTest::default();
    let _ = test.init_user().await;

    let test = ViewTest::new(&test).await;
    let view1 = test.view.clone();
    let view2 = create_view(&test.sdk, &test.app.id).await;
    let view3 = create_view(&test.sdk, &test.app.id).await;
    let view_ids = vec![view1.id.clone(), view2.id.clone(), view3.id.clone()];

    let query = QueryAppRequest {
        app_ids: vec![test.app.id.clone()],
    };
    let app = read_app(&test.sdk, query.clone()).await;
    assert_eq!(app.belongings.len(), view_ids.len());
    test.delete_views(view_ids.clone()).await;

    assert_eq!(read_app(&test.sdk, query).await.belongings.len(), 0);
    assert_eq!(read_trash(&test.sdk).await.len(), view_ids.len());
}

#[tokio::test]
async fn view_delete_all_permanent() {
    let test = FlowySDKTest::default();
    let _ = test.init_user().await;

    let test = ViewTest::new(&test).await;
    let view1 = test.view.clone();
    let view2 = create_view(&test.sdk, &test.app.id).await;

    let view_ids = vec![view1.id.clone(), view2.id.clone()];
    test.delete_views_permanent(view_ids).await;

    let query = QueryAppRequest {
        app_ids: vec![test.app.id.clone()],
    };
    assert_eq!(read_app(&test.sdk, query).await.belongings.len(), 0);
    assert_eq!(read_trash(&test.sdk).await.len(), 0);
}

#[tokio::test]
async fn view_open_doc() {
    let test = FlowySDKTest::default();
    let _ = test.init_user().await;

    let test = ViewTest::new(&test).await;
    let request = QueryViewRequest {
        view_ids: vec![test.view.id.clone()],
    };
    let _ = open_view(&test.sdk, request).await;
}
