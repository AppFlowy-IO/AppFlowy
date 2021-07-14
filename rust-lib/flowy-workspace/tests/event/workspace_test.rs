use flowy_test::EventTester;
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, WorkspaceDetail},
    event::WorkspaceEvent::*,
    prelude::*,
};

#[test]
fn workspace_create_test() {
    let request = CreateWorkspaceRequest {
        name: "123workspace".to_owned(),
        desc: "".to_owned(),
    };

    let response = EventTester::new(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<WorkspaceDetail>();
    dbg!(&response);
}
