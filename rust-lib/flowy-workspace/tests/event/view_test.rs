use crate::helper::*;

use flowy_workspace::entities::view::*;

#[test]
fn view_create_success() { let _ = create_view(); }

#[test]
fn view_update_with_trash_flag_and_read_with_trash_flag_success() {
    let view_id = create_view_with_trash_flag();
    let query = QueryViewRequest::new(&view_id).set_is_trash(true);
    let _ = read_view(query);
}

#[test]
#[should_panic]
fn view_update_with_trash_flag_and_read_without_trash_flag_fail() {
    let view_id = create_view_with_trash_flag();
    let query = QueryViewRequest::new(&view_id);
    let _ = read_view(query);
}

pub fn create_view_with_trash_flag() -> String {
    let view = create_view();
    let request = UpdateViewRequest {
        view_id: view.id.clone(),
        name: None,
        desc: None,
        thumbnail: None,
        is_trash: Some(true),
    };
    update_view(request);

    view.id
}
