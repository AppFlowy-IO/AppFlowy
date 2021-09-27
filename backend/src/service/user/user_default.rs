use crate::{
    service::{
        app::sql_builder::NewAppSqlBuilder as AppBuilder,
        view::create_view_with_transaction,
        workspace::sql_builder::NewWorkspaceBuilder as WorkspaceBuilder,
    },
    sqlx_ext::{map_sqlx_error, DBTransaction},
};
use flowy_net::errors::ServerError;
use flowy_workspace::{
    entities::view::DOC_DEFAULT_DATA,
    protobuf::{App, CreateViewParams, View, ViewType, Workspace},
};

pub async fn create_default_workspace(
    transaction: &mut DBTransaction<'_>,
    user_id: &str,
) -> Result<Workspace, ServerError> {
    let workspace = create_workspace(transaction, user_id).await?;
    let app = create_app(transaction, user_id, &workspace).await?;
    let _ = create_view(transaction, &app).await?;

    Ok(workspace)
}

async fn create_workspace(transaction: &mut DBTransaction<'_>, user_id: &str) -> Result<Workspace, ServerError> {
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
    let params = CreateViewParams {
        belong_to_id: app.id.clone(),
        name: "DefaultView".to_string(),
        desc: "View created by AppFlowy".to_string(),
        thumbnail: "123.png".to_string(),
        view_type: ViewType::Doc,
        data: DOC_DEFAULT_DATA.to_string(),
        unknown_fields: Default::default(),
        cached_size: Default::default(),
    };

    let _name = "DefaultView".to_string();
    let _desc = "View created by AppFlowy Server".to_string();
    let _thumbnail = "http://1.png".to_string();

    let view = create_view_with_transaction(transaction, params).await?;

    Ok(view)
}
