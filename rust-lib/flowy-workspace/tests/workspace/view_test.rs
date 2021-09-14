use crate::helper::*;

use flowy_workspace::entities::view::*;

#[test]
fn view_move_to_trash() {
    let test = ViewTest::new();
    test.move_view_to_trash();

    let query = QueryViewRequest::new(&test.view.id).trash();
    let view = read_view(&test.sdk, query);
    assert_eq!(view, test.view);
}

#[test]
#[should_panic]
fn view_move_to_trash2() {
    let test = ViewTest::new();
    test.move_view_to_trash();
    let query = QueryViewRequest::new(&test.view.id);
    let _ = read_view(&test.sdk, query);
}

#[test]
fn view_open_doc() {
    let test = ViewTest::new();

    let request = OpenViewRequest {
        view_id: test.view.id.clone(),
    };
    let _ = open_view(&test.sdk, request);
}

#[test]
fn view_update_doc() {
    let test = ViewTest::new();

    let new_data = "123";
    let request = SaveViewDataRequest {
        view_id: test.view.id.clone(),
        data: new_data.to_string(),
    };

    update_view_data(&test.sdk, request);

    let request = OpenViewRequest {
        view_id: test.view.id.clone(),
    };
    let doc = open_view(&test.sdk, request);
    assert_eq!(&doc.data, new_data);
}

#[test]
fn view_update_big_doc() {
    let test = ViewTest::new();
    let new_data = "flutter ❤️ rust".repeat(1000000);
    let request = SaveViewDataRequest {
        view_id: test.view.id.clone(),
        data: new_data.to_string(),
    };

    update_view_data(&test.sdk, request);

    let doc = open_view(
        &test.sdk,
        OpenViewRequest {
            view_id: test.view.id.clone(),
        },
    );
    assert_eq!(doc.data, new_data);
}
