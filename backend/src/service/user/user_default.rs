use crate::{
    service::{
        app::sql_builder::NewAppSqlBuilder as AppBuilder,
        workspace::sql_builder::NewWorkspaceBuilder as WorkspaceBuilder,
    },
    sqlx_ext::{map_sqlx_error, DBTransaction},
};

use crate::service::view::{create_view_with_args, sql_builder::NewViewSqlBuilder};
use backend_service::errors::ServerError;
use chrono::Utc;
use flowy_document_infra::user_default::doc_initial_string;
use flowy_workspace_infra::protobuf::Workspace;
use std::convert::TryInto;

pub async fn create_default_workspace(
    transaction: &mut DBTransaction<'_>,
    user_id: &str,
) -> Result<Workspace, ServerError> {
    let time = Utc::now();
    let workspace: Workspace = flowy_workspace_infra::user_default::create_default_workspace(time)
        .try_into()
        .unwrap();

    let mut cloned_workspace = workspace.clone();
    let mut apps = cloned_workspace.take_apps();

    let (sql, args, _) = WorkspaceBuilder::from_workspace(user_id, cloned_workspace)?.build()?;
    let _ = sqlx::query_with(&sql, args)
        .execute(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    for mut app in apps.take_items() {
        let mut views = app.take_belongings();
        let (sql, args, _) = AppBuilder::from_app(user_id, app)?.build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;

        for view in views.take_items() {
            let (sql, args, view) = NewViewSqlBuilder::from_view(view)?.build()?;
            let _ = create_view_with_args(transaction, sql, args, view, doc_initial_string()).await?;
        }
    }
    Ok(workspace)
}
