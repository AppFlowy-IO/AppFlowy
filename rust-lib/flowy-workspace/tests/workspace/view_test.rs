use flowy_test::{workspace::*, FlowyTest};
use flowy_workspace::entities::{
    app::QueryAppRequest,
    trash::{TrashIdentifier, TrashType},
    view::*,
};

#[tokio::test]
#[should_panic]
async fn view_delete() {
    let test = FlowyTest::setup();
    let _ = test.init_user();

    let test = ViewTest::new(&test).await;
    test.delete_views(vec![test.view.id.clone()]).await;
    let query = QueryViewRequest {
        view_ids: vec![test.view.id.clone()],
    };
    let _ = read_view(&test.sdk, query).await;
}

#[tokio::test]
async fn view_delete_then_putback() {
    let test = FlowyTest::setup();
    let _ = test.init_user();

    let test = ViewTest::new(&test).await;
    test.delete_views(vec![test.view.id.clone()]).await;
    putback_trash(
        &test.sdk,
        TrashIdentifier {
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
    let test = FlowyTest::setup();
    let _ = test.init_user();

    let test = ViewTest::new(&test).await;
    let view1 = test.view.clone();
    let view2 = create_view(&test.sdk, &test.app.id).await;
    let view3 = create_view(&test.sdk, &test.app.id).await;
    let view_ids = vec![view1.id.clone(), view2.id.clone(), view3.id.clone()];

    let query = QueryAppRequest::new(&test.app.id);
    let app = read_app(&test.sdk, query.clone()).await;
    assert_eq!(app.belongings.len(), view_ids.len());
    test.delete_views(view_ids.clone()).await;

    assert_eq!(read_app(&test.sdk, query).await.belongings.len(), 0);
    assert_eq!(read_trash(&test.sdk).await.len(), view_ids.len());
}

#[tokio::test]
async fn view_delete_all_permanent() {
    let test = FlowyTest::setup();
    let _ = test.init_user();

    let test = ViewTest::new(&test).await;
    let view1 = test.view.clone();
    let view2 = create_view(&test.sdk, &test.app.id).await;

    let view_ids = vec![view1.id.clone(), view2.id.clone()];
    test.delete_views_permanent(view_ids).await;

    let query = QueryAppRequest::new(&test.app.id);
    assert_eq!(read_app(&test.sdk, query).await.belongings.len(), 0);
    assert_eq!(read_trash(&test.sdk).await.len(), 0);
}

#[tokio::test]
async fn view_open_doc() {
    let test = FlowyTest::setup();
    let _ = test.init_user().await;

    let test = ViewTest::new(&test).await;
    let request = QueryViewRequest {
        view_ids: vec![test.view.id.clone()],
    };
    let _ = open_view(&test.sdk, request).await;
}
