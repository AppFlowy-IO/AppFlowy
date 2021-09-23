use anyhow::Context;
use sqlx::{postgres::PgArguments, PgPool, Postgres};

use flowy_net::{
    errors::{invalid_params, ServerError},
    response::FlowyResponse,
};
use flowy_workspace::{
    entities::workspace::parser::{WorkspaceDesc, WorkspaceId, WorkspaceName},
    protobuf::{App, CreateWorkspaceParams, RepeatedApp, RepeatedWorkspace, UpdateWorkspaceParams},
};

use crate::{
    entities::workspace::{AppTable, WorkspaceTable, WORKSPACE_TABLE},
    service::{user::LoggedUser, view::read_views_belong_to_id, workspace::sql_builder::*},
    sqlx_ext::*,
};

use super::sql_builder::NewWorkspaceBuilder;

pub(crate) async fn create_workspace(
    pool: &PgPool,
    params: CreateWorkspaceParams,
    logged_user: LoggedUser,
) -> Result<FlowyResponse, ServerError> {
    let name = WorkspaceName::parse(params.get_name().to_owned()).map_err(invalid_params)?;
    let desc = WorkspaceDesc::parse(params.get_desc().to_owned()).map_err(invalid_params)?;
    let user_id = logged_user.as_uuid()?.to_string();

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create workspace")?;

    let (sql, args, workspace) = NewWorkspaceBuilder::new(&user_id)
        .name(name.as_ref())
        .desc(desc.as_ref())
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create workspace.")?;

    FlowyResponse::success().pb(workspace)
}

pub(crate) async fn update_workspace(
    pool: &PgPool,
    params: UpdateWorkspaceParams,
) -> Result<FlowyResponse, ServerError> {
    let workspace_id = check_workspace_id(params.get_id().to_owned())?;
    let name = match params.has_name() {
        false => None,
        true => {
            let name = WorkspaceName::parse(params.get_name().to_owned())
                .map_err(invalid_params)?
                .0;
            Some(name)
        },
    };

    let desc = match params.has_desc() {
        false => None,
        true => {
            let desc = WorkspaceDesc::parse(params.get_desc().to_owned())
                .map_err(invalid_params)?
                .0;
            Some(desc)
        },
    };

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update workspace")?;

    let (sql, args) = SqlBuilder::update(WORKSPACE_TABLE)
        .add_some_arg("name", name)
        .add_some_arg("description", desc)
        .and_where_eq("id", workspace_id)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update workspace.")?;

    Ok(FlowyResponse::success())
}

pub(crate) async fn delete_workspace(
    pool: &PgPool,
    workspace_id: &str,
) -> Result<FlowyResponse, ServerError> {
    let workspace_id = check_workspace_id(workspace_id.to_owned())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete workspace")?;

    let (sql, args) = SqlBuilder::delete(WORKSPACE_TABLE)
        .and_where_eq("id", workspace_id)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete workspace.")?;

    Ok(FlowyResponse::success())
}

pub async fn read_workspaces(
    pool: &PgPool,
    workspace_id: Option<String>,
    logged_user: LoggedUser,
) -> Result<FlowyResponse, ServerError> {
    let user_id = logged_user.as_uuid()?.to_string();
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read workspace")?;

    let mut builder = SqlBuilder::select(WORKSPACE_TABLE)
        .add_field("*")
        .and_where_eq("user_id", &user_id);

    if let Some(workspace_id) = workspace_id {
        let workspace_id = check_workspace_id(workspace_id)?;
        builder = builder.and_where_eq("id", workspace_id);
    }

    let (sql, args) = builder.build()?;
    let tables = sqlx::query_as_with::<Postgres, WorkspaceTable, PgArguments>(&sql, args)
        .fetch_all(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    let mut repeated_workspace = RepeatedWorkspace::default();
    let mut workspaces = vec![];
    // Opti: combine the query
    for table in tables {
        let mut apps = read_apps_belong_to_workspace(&mut transaction, &table.id.to_string())
            .await
            .context("Get workspace app")
            .unwrap_or(RepeatedApp::default());

        for app in &mut apps.items {
            let views = read_views_belong_to_id(&mut transaction, &app.id).await?;
            app.mut_belongings().set_items(views.into());
        }

        let workspace = make_workspace_from_table(table, Some(apps));
        workspaces.push(workspace);
    }
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read workspace.")?;

    repeated_workspace.set_items(workspaces.into());
    FlowyResponse::success().pb(repeated_workspace)
}

// transaction must be commit from caller
async fn read_apps_belong_to_workspace<'c>(
    transaction: &mut DBTransaction<'_>,
    workspace_id: &str,
) -> Result<RepeatedApp, ServerError> {
    let transaction = transaction;
    let workspace_id = WorkspaceId::parse(workspace_id.to_owned()).map_err(invalid_params)?;
    let (sql, args) = SqlBuilder::select("app_table")
        .add_field("*")
        .and_where_eq("workspace_id", workspace_id.0)
        .build()?;

    let tables = sqlx::query_as_with::<Postgres, AppTable, PgArguments>(&sql, args)
        .fetch_all(transaction)
        .await
        .map_err(map_sqlx_error)?;

    let apps = tables
        .into_iter()
        .map(|table| table.into())
        .collect::<Vec<App>>();

    let mut repeated_app = RepeatedApp::default();
    repeated_app.set_items(apps.into());
    Ok(repeated_app)
}
