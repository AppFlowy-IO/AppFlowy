// use crate::sql_tables::workspace::Workspace;
//
// #[derive(Default, Debug, ProtoBuf)]
// pub struct WorkspaceDetail {
//     #[pb(index = 1)]
//     pub workspace: Workspace,
//
//     #[pb(index = 2)]
//     pub apps: Vec<App>,
// }

// use crate::entities::{RepeatedApp, Workspace};
// use flowy_derive::ProtoBuf;
// use flowy_traits::cqrs::Identifiable;
//
// #[derive(ProtoBuf, Default, Debug)]
// pub struct WorkspaceQuery {
//     #[pb(index = 1)]
//     pub workspace_id: String,
//
//     #[pb(index = 2)]
//     pub read_apps: bool,
// }
//
// impl WorkspaceQuery {
//     pub fn read_workspace(workspace_id: &str) -> Self {
//         WorkspaceQuery {
//             workspace_id: workspace_id.to_string(),
//             read_apps: false,
//         }
//     }
//
//     pub fn read_apps(workspace_id: &str) -> Self {
//         WorkspaceQuery {
//             workspace_id: workspace_id.to_string(),
//             read_apps: true,
//         }
//     }
// }
//
// #[derive(Default, Debug, ProtoBuf)]
// pub struct WorkspaceQueryResult {
//     #[pb(index = 1, oneof)]
//     pub workspace: Option<Workspace>,
//
//     #[pb(index = 2, oneof)]
//     pub apps: Option<RepeatedApp>,
//
//     #[pb(index = 100)]
//     pub error: String,
// }
