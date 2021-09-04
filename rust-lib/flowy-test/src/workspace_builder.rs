use super::builder::Builder;
use crate::{builder::TestContext, helper::FlowyTestSDK};
use flowy_workspace::{
    entities::{app::App, view::View, workspace::*},
    errors::WorkspaceError,
    event::WorkspaceEvent::*,
};

pub enum WorkspaceAction {
    CreateWorkspace(CreateWorkspaceRequest),
    ReadWorkspace(QueryWorkspaceRequest),
}

type Inner = Builder<WorkspaceError>;

pub struct WorkspaceTestBuilder {
    workspace: Option<Workspace>,
    app: Option<App>,
    view: Option<View>,
    inner: Builder<WorkspaceError>,
}

impl WorkspaceTestBuilder {
    pub fn new(sdk: FlowyTestSDK) -> Self {
        Self {
            workspace: None,
            app: None,
            view: None,
            inner: Builder::test(TestContext::new(sdk)),
        }
    }

    pub fn run(mut self, actions: Vec<WorkspaceAction>) {
        let inner = self.inner;
        for action in actions {
            match action {
                WorkspaceAction::CreateWorkspace(request) => {
                    let workspace = inner
                        .clone()
                        .event(CreateWorkspace)
                        .request(request)
                        .sync_send()
                        .parse::<Workspace>();
                    self.workspace = Some(workspace);
                },
                WorkspaceAction::ReadWorkspace(request) => {
                    let mut repeated_workspace = inner
                        .clone()
                        .event(ReadWorkspaces)
                        .request(request)
                        .sync_send()
                        .parse::<RepeatedWorkspace>();

                    debug_assert_eq!(repeated_workspace.len(), 1, "Default workspace not found");
                    repeated_workspace.drain(..1).collect::<Vec<Workspace>>().pop()
                },
            }
        }
    }
}
