use crate::helper::*;

use flowy_test::builder::UserTestBuilder;
use flowy_workspace::entities::view::*;

#[test]
fn view_create() {
    let _ = UserTestBuilder::new().sign_up();

    let workspace = create_workspace("Workspace", "");
    let _ = create_view(&workspace.id);
}

#[test]
fn view_set_trash_flag() {
    let _ = UserTestBuilder::new().sign_up();
    let view_id = create_view_with_trash_flag();
    let query = QueryViewRequest::new(&view_id).set_is_trash(true);
    let _ = read_view(query);
}

#[test]
#[should_panic]
fn view_set_trash_flag2() {
    let _ = UserTestBuilder::new().sign_up();

    let view_id = create_view_with_trash_flag();
    let query = QueryViewRequest::new(&view_id);
    let _ = read_view(query);
}

fn create_view_with_trash_flag() -> String {
    let workspace = create_workspace("Workspace", "");
    let view = create_view(&workspace.id);
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
