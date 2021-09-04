use crate::helper::*;

use flowy_test::{FlowyEnv, FlowyTestSDK};
use flowy_workspace::entities::view::*;

#[test]
fn view_create() {
    let sdk = FlowyEnv::setup().sdk;
    let workspace = create_workspace(&sdk, "Workspace", "");
    let _ = create_view(&sdk, &workspace.id);
}

#[test]
fn view_set_trash_flag() {
    let sdk = FlowyEnv::setup().sdk;
    let view_id = create_view_with_trash_flag(&sdk);
    let query = QueryViewRequest::new(&view_id).set_is_trash(true);
    let _ = read_view(&sdk, query);
}

#[test]
#[should_panic]
fn view_set_trash_flag2() {
    let sdk = FlowyEnv::setup().sdk;

    let view_id = create_view_with_trash_flag(&sdk);
    let query = QueryViewRequest::new(&view_id);
    let _ = read_view(&sdk, query);
}

fn create_view_with_trash_flag(sdk: &FlowyTestSDK) -> String {
    let workspace = create_workspace(sdk, "Workspace", "");
    let view = create_view(sdk, &workspace.id);
    let request = UpdateViewRequest {
        view_id: view.id.clone(),
        name: None,
        desc: None,
        thumbnail: None,
        is_trash: Some(true),
    };
    update_view(sdk, request);

    view.id
}
