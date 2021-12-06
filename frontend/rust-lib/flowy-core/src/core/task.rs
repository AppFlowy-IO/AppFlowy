use crate::{errors::WorkspaceError, services::WorkspaceController};
use flowy_workspace_infra::entities::workspace::{QueryWorkspaceRequest, RepeatedWorkspace, WorkspaceIdentifier};
use lib_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn read_workspaces_handler(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<RepeatedWorkspace, WorkspaceError> {
    let params: WorkspaceIdentifier = data.into_inner().try_into()?;
    let user_id = controller.user.user_id()?;
    let workspaces = controller.read_local_workspaces(
        params.workspace_id.clone(),
        &user_id,
        &*controller.database.db_connection()?,
    )?;
    let _ = controller.read_workspaces_on_server(user_id, params);

    data_result(workspaces)
}

// #[tracing::instrument(level = "debug", skip(self), err)]
// fn read_workspaces_on_server(&self, user_id: String, params:
// WorkspaceIdentifier) -> Result<(), WorkspaceError> {     let (token, server)
// = self.token_with_server()?;     let workspace_sql =
// self.workspace_sql.clone();     let app_ctrl = self.app_controller.clone();
//     let view_ctrl = self.view_controller.clone();
//     let conn = self.database.db_connection()?;
//     tokio::spawn(async move {
//         // Opti: handle the error and retry?
//         let workspaces = server.read_workspace(&token, params).await?;
//         let _ = (&*conn).immediate_transaction::<_, WorkspaceError, _>(|| {
//             tracing::debug!("Save {} workspace", workspaces.len());
//             for workspace in &workspaces.items {
//                 let m_workspace = workspace.clone();
//                 let apps = m_workspace.apps.clone().into_inner();
//                 let workspace_table = WorkspaceTable::new(m_workspace,
// &user_id);
//
//                 let _ = workspace_sql.create_workspace(workspace_table,
// &*conn)?;                 tracing::debug!("Save {} apps", apps.len());
//                 for app in apps {
//                     let views = app.belongings.clone().into_inner();
//                     match app_ctrl.save_app(app, &*conn) {
//                         Ok(_) => {},
//                         Err(e) => log::error!("create app failed: {:?}", e),
//                     }
//
//                     tracing::debug!("Save {} views", views.len());
//                     for view in views {
//                         match view_ctrl.save_view(view, &*conn) {
//                             Ok(_) => {},
//                             Err(e) => log::error!("create view failed: {:?}",
// e),                         }
//                     }
//                 }
//             }
//             Ok(())
//         })?;
//
//         send_dart_notification(&token,
// WorkspaceNotification::WorkspaceListUpdated)             .payload(workspaces)
//             .send();
//         Result::<(), WorkspaceError>::Ok(())
//     });
//
//     Ok(())
// }
