use super::persistence::NewWorkspaceBuilder;
use crate::{
    entities::logged_user::LoggedUser,
    services::core::{
        app::{controller::read_app, persistence::AppTable},
        workspace::persistence::*,
    },
    util::sqlx_ext::*,
};
use anyhow::Context;
use backend_service::errors::{invalid_params, ServerError};
use flowy_core_data_model::{
    parser::workspace::WorkspaceIdentify,
<<<<<<< HEAD
<<<<<<< HEAD
    protobuf::{RepeatedApp, RepeatedWorkspace, Workspace},
=======
    protobuf::{RepeatedApp as RepeatedAppPB, RepeatedWorkspace as RepeatedWorkspacePB, Workspace as WorkspacePB},
>>>>>>> upstream/main
=======
    protobuf::{RepeatedApp as RepeatedAppPB, RepeatedWorkspace as RepeatedWorkspacePB, Workspace as WorkspacePB},
>>>>>>> upstream/main
};
use sqlx::{postgres::PgArguments, Postgres};
use uuid::Uuid;

pub(crate) async fn create_workspace(
    transaction: &mut DBTransaction<'_>,
    name: &str,
    desc: &str,
    logged_user: LoggedUser,
) -> Result<WorkspacePB, ServerError> {
    let user_id = logged_user.as_uuid()?.to_string();
    let (sql, args, workspace) = NewWorkspaceBuilder::new(&user_id).name(name).desc(desc).build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(workspace)
}

pub(crate) async fn update_workspace(
    transaction: &mut DBTransaction<'_>,
    workspace_id: Uuid,
    name: Option<String>,
    desc: Option<String>,
) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::update(WORKSPACE_TABLE)
        .add_some_arg("name", name)
        .add_some_arg("description", desc)
        .and_where_eq("id", workspace_id)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

pub(crate) async fn delete_workspace(
    transaction: &mut DBTransaction<'_>,
    workspace_id: Uuid,
) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::delete(WORKSPACE_TABLE)
        .and_where_eq("id", workspace_id)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

#[tracing::instrument(skip(transaction, logged_user), err)]
pub async fn read_workspaces(
    transaction: &mut DBTransaction<'_>,
    workspace_id: Option<String>,
    logged_user: LoggedUser,
) -> Result<RepeatedWorkspacePB, ServerError> {
    let user_id = logged_user.as_uuid()?.to_string();

    let mut builder = SqlBuilder::select(WORKSPACE_TABLE)
        .add_field("*")
        .and_where_eq("user_id", &user_id);

    if let Some(workspace_id) = workspace_id {
        let workspace_id = check_workspace_id(workspace_id)?;
        builder = builder.and_where_eq("id", workspace_id);
    }

    let (sql, args) = builder.build()?;
    let tables = sqlx::query_as_with::<Postgres, WorkspaceTable, PgArguments>(&sql, args)
        .fetch_all(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    let mut repeated_workspace = RepeatedWorkspacePB::default();
    let mut workspaces = vec![];
    // Opti: combine the query
    for table in tables {
        let apps = read_workspace_apps(
            &logged_user,
            transaction as &mut DBTransaction<'_>,
            &table.id.to_string(),
        )
        .await
        .context("Get workspace app")
        .unwrap_or_default();

        let mut workspace: WorkspacePB = table.into();
        workspace.set_apps(apps);
        workspaces.push(workspace);
    }

    repeated_workspace.set_items(workspaces.into());
    Ok(repeated_workspace)
}

#[tracing::instrument(skip(transaction, user), fields(app_count), err)]
async fn read_workspace_apps<'c>(
    user: &LoggedUser,
    transaction: &mut DBTransaction<'_>,
    workspace_id: &str,
<<<<<<< HEAD
<<<<<<< HEAD
) -> Result<RepeatedApp, ServerError> {
=======
) -> Result<RepeatedAppPB, ServerError> {
>>>>>>> upstream/main
=======
) -> Result<RepeatedAppPB, ServerError> {
>>>>>>> upstream/main
    let workspace_id = WorkspaceIdentify::parse(workspace_id.to_owned()).map_err(invalid_params)?;
    let (sql, args) = SqlBuilder::select("app_table")
        .add_field("*")
        .and_where_eq("workspace_id", workspace_id.0)
        .build()?;

    let app_tables = sqlx::query_as_with::<Postgres, AppTable, PgArguments>(&sql, args)
        .fetch_all(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    tracing::Span::current().record("app_count", &app_tables.len());
    let mut apps = vec![];
    for table in app_tables {
        let app = read_app(transaction, table.id, user).await?;
        apps.push(app);
    }

    let mut repeated_app = RepeatedAppPB::default();
    repeated_app.set_items(apps.into());
    Ok(repeated_app)
}
