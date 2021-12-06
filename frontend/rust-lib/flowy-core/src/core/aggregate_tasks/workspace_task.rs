use crate::{
    core::CoreContext,
    errors::WorkspaceError,
    notify::{send_dart_notification, WorkspaceNotification},
    services::workspace::sql::{WorkspaceTable, WorkspaceTableSql},
};
use flowy_workspace_infra::entities::workspace::WorkspaceIdentifier;
use lib_dispatch::prelude::Unit;
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(core), err)]
pub fn read_workspaces_on_server(
    core: Unit<Arc<CoreContext>>,
    user_id: String,
    params: WorkspaceIdentifier,
) -> Result<(), WorkspaceError> {
    let (token, server) = (core.user.token()?, core.server.clone());
    let app_ctrl = core.app_controller.clone();
    let view_ctrl = core.view_controller.clone();
    let conn = core.database.db_connection()?;

    tokio::spawn(async move {
        // Opti: handle the error and retry?
        let workspaces = server.read_workspace(&token, params).await?;
        let _ = (&*conn).immediate_transaction::<_, WorkspaceError, _>(|| {
            tracing::debug!("Save {} workspace", workspaces.len());
            for workspace in &workspaces.items {
                let m_workspace = workspace.clone();
                let apps = m_workspace.apps.clone().into_inner();
                let workspace_table = WorkspaceTable::new(m_workspace, &user_id);

                let _ = WorkspaceTableSql::create_workspace(workspace_table, &*conn)?;
                tracing::debug!("Save {} apps", apps.len());
                for app in apps {
                    let views = app.belongings.clone().into_inner();
                    match app_ctrl.save_app(app, &*conn) {
                        Ok(_) => {},
                        Err(e) => log::error!("create app failed: {:?}", e),
                    }

                    tracing::debug!("Save {} views", views.len());
                    for view in views {
                        match view_ctrl.save_view(view, &*conn) {
                            Ok(_) => {},
                            Err(e) => log::error!("create view failed: {:?}", e),
                        }
                    }
                }
            }
            Ok(())
        })?;

        send_dart_notification(&token, WorkspaceNotification::WorkspaceListUpdated)
            .payload(workspaces)
            .send();
        Result::<(), WorkspaceError>::Ok(())
    });

    Ok(())
}
