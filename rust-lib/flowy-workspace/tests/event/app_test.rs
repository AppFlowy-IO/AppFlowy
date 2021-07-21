use crate::helper::*;
use flowy_test::builder::WorkspaceTestBuilder;
use flowy_workspace::{
    entities::{
        app::{App, CreateAppRequest, QueryAppRequest},
        view::*,
        workspace::Workspace,
    },
    event::WorkspaceEvent::{CreateApp, GetCurWorkspace},
};

#[test]
fn app_create_success() {
    let workspace = create_workspace("Workspace", "");
    let app = create_app("App A", "AppFlowy Github Project", &workspace.id);
    dbg!(&app);
}

#[test]
fn app_create_and_then_get_success() {
    let workspace = create_workspace("Workspace", "");
    let app = create_app("App A", "AppFlowy Github Project", &workspace.id);
    let request = QueryAppRequest {
        app_id: app.id.clone(),
        read_views: false,
    };
    let app_from_db = get_app(request);
    assert_eq!(app_from_db, app);
}

#[test]
fn app_create_with_view_and_then_get_success() {
    let workspace = create_workspace("Workspace", "");
    let app = create_app("App A", "AppFlowy Github Project", &workspace.id);
    let request_a = CreateViewRequest {
        app_id: app.id.clone(),
        name: "View A".to_string(),
        desc: "".to_string(),
        thumbnail: None,
        view_type: ViewType::Docs,
    };

    let request_b = CreateViewRequest {
        app_id: app.id.clone(),
        name: "View B".to_string(),
        desc: "".to_string(),
        thumbnail: None,
        view_type: ViewType::Docs,
    };

    let view_a = create_view(request_a);
    let view_b = create_view(request_b);

    let query = QueryAppRequest {
        app_id: app.id.clone(),
        read_views: true,
    };
    let view_from_db = get_app(query);

    assert_eq!(view_from_db.views[0], view_a);
    assert_eq!(view_from_db.views[1], view_b);
}

// TODO 1) test update app 2) delete app
