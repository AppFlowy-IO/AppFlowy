use crate::{
    sqlx_ext::{map_sqlx_error, DBTransaction},
    workspace_service::{
        app::sql_builder::Builder as AppBuilder,
        view::sql_builder::Builder as ViewBuilder,
        workspace::sql_builder::Builder as WorkspaceBuilder,
    },
};

use flowy_net::errors::ServerError;
use flowy_workspace::protobuf::{App, View, ViewType, Workspace};

pub async fn create_default_workspace(
    transaction: &mut DBTransaction<'_>,
    user_id: &str,
) -> Result<Workspace, ServerError> {
    let workspace = create_workspace(transaction, user_id).await?;
    let app = create_app(transaction, user_id, &workspace).await?;
    let _ = create_view(transaction, &app).await?;

    Ok(workspace)
}

async fn create_workspace(
    transaction: &mut DBTransaction<'_>,
    user_id: &str,
) -> Result<Workspace, ServerError> {
    let (sql, args, workspace) = WorkspaceBuilder::new(user_id.as_ref())
        .name("DefaultWorkspace")
        .desc("Workspace created by AppFlowy")
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(workspace)
}

async fn create_app(
    transaction: &mut DBTransaction<'_>,
    user_id: &str,
    workspace: &Workspace,
) -> Result<App, ServerError> {
    let (sql, args, app) = AppBuilder::new(user_id, &workspace.id)
        .name("DefaultApp")
        .desc("App created by AppFlowy")
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(app)
}

async fn create_view(transaction: &mut DBTransaction<'_>, app: &App) -> Result<View, ServerError> {
    let (sql, args, view) = ViewBuilder::new(&app.id)
        .name("DefaultView")
        .desc("View created by AppFlowy")
        .thumbnail("https://view.png")
        .view_type(ViewType::Doc)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;
    Ok(view)
}
