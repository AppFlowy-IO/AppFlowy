use crate::{
    service::{
        app::sql_builder::NewAppSqlBuilder as AppBuilder,
        view::create_view,
        workspace::sql_builder::NewWorkspaceBuilder as WorkspaceBuilder,
    },
    sqlx_ext::{map_sqlx_error, DBTransaction},
};

use flowy_document::services::doc::doc_initial_string;
use flowy_net::errors::ServerError;
use flowy_workspace_infra::protobuf::{App, CreateViewParams, View, ViewType, Workspace};

pub async fn create_default_workspace(
    transaction: &mut DBTransaction<'_>,
    user_id: &str,
) -> Result<Workspace, ServerError> {
    let workspace = create_workspace(transaction, user_id).await?;
    let app = create_app(transaction, user_id, &workspace).await?;
    let _ = create_default_view(transaction, &app).await?;

    Ok(workspace)
}

async fn create_workspace(transaction: &mut DBTransaction<'_>, user_id: &str) -> Result<Workspace, ServerError> {
    let (sql, args, workspace) = WorkspaceBuilder::new(user_id.as_ref())
        .name("DefaultWorkspace")
        .desc("")
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
        .name("Getting Started")
        .desc("")
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(app)
}

async fn create_default_view(transaction: &mut DBTransaction<'_>, app: &App) -> Result<View, ServerError> {
    let params = CreateViewParams {
        belong_to_id: app.id.clone(),
        name: "Read Me".to_string(),
        desc: "".to_string(),
        thumbnail: "".to_string(),
        view_type: ViewType::Doc,
        data: doc_initial_string(),
        unknown_fields: Default::default(),
        cached_size: Default::default(),
    };

    let view = create_view(transaction, params).await?;

    Ok(view)
}
