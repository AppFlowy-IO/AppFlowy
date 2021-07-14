use crate::helper::WorkspaceEventTester;
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, WorkspaceDetail},
    event::WorkspaceEvent::*,
    prelude::*,
};

#[test]
#[should_panic]
fn workspace_create_test() {
    let request = CreateWorkspaceRequest {
        name: "".to_owned(),
        desc: "".to_owned(),
    };

    let response = WorkspaceEventTester::new(CreateWorkspace)
        .request(request)
        .sync_send()
        .parse::<WorkspaceDetail>();
    dbg!(&response);
}
