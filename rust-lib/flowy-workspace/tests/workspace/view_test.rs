use flowy_test::{workspace::*, FlowyTest};
use flowy_workspace::entities::{
    trash::{TrashIdentifier, TrashType},
    view::*,
};

#[tokio::test]
#[should_panic]
async fn view_delete() {
    let test = FlowyTest::setup();
    let _ = test.init_user();

    let test = ViewTest::new(&test).await;
    test.delete().await;
    let query = QueryViewRequest::new(&test.view.id);
    let _ = read_view(&test.sdk, query).await;
}

#[tokio::test]
async fn view_delete_and_putback() {
    let test = FlowyTest::setup();
    let _ = test.init_user();

    let test = ViewTest::new(&test).await;
    test.delete().await;
    putback_trash(
        &test.sdk,
        TrashIdentifier {
            id: test.view.id.clone(),
            ty: TrashType::View,
        },
    )
    .await;

    let query = QueryViewRequest::new(&test.view.id);
    let view = read_view(&test.sdk, query).await;
    assert_eq!(&view, &test.view);
}

#[tokio::test]
async fn view_open_doc() {
    let test = FlowyTest::setup();
    let _ = test.init_user().await;

    let test = ViewTest::new(&test).await;
    let request = OpenViewRequest {
        view_id: test.view.id.clone(),
    };
    let _ = open_view(&test.sdk, request).await;
}

#[test]
fn view_update_doc() {
    // let test = ViewTest::new();
    // let new_data = DeltaBuilder::new().insert("flutter ❤️
    // rust").build().into_bytes(); let request = SaveViewDataRequest {
    //     view_id: test.view.id.clone(),
    //     data: new_data.clone(),
    // };
    //
    // update_view_data(&test.sdk, request);
    //
    // let request = OpenViewRequest {
    //     view_id: test.view.id.clone(),
    // };
    // let doc = open_view(&test.sdk, request);
    // assert_eq!(doc.data, new_data);
}

#[test]
fn view_update_big_doc() {
    // let test = ViewTest::new();
    // let new_data = DeltaBuilder::new().insert(&"flutter ❤️
    // rust".repeat(1000000)).build().into_bytes();
    //
    // let request = SaveViewDataRequest {
    //     view_id: test.view.id.clone(),
    //     data: new_data.clone(),
    // };
    //
    // update_view_data(&test.sdk, request);
    //
    // let doc = open_view(
    //     &test.sdk,
    //     OpenViewRequest {
    //         view_id: test.view.id.clone(),
    //     },
    // );
    // assert_eq!(doc.data, new_data);
}
