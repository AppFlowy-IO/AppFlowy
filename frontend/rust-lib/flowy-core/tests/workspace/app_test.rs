use flowy_core::entities::{
    app::QueryAppRequest,
    trash::{TrashId, TrashType},
    view::*,
};
use flowy_test::helper::*;

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

// #[tokio::test]
// async fn app_set_trash_flag() {
//     let test = AppTest::new().await;
//     test.delete().await;
//
//     let query = QueryAppRequest::new(&test.app.id).trash();
//     let _ = read_app(&test.sdk, query);
// }
//
// #[tokio::test]
// #[should_panic]
// async fn app_set_trash_flag_2() {
//     let test = AppTest::new().await;
//     test.move_app_to_trash().await;
//     let query = QueryAppRequest::new(&test.app.id);
//     let _ = read_app(&test.sdk, query);
// }
