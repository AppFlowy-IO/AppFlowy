use crate::{
    entities::workspace::WorkspaceTable,
    sqlx_ext::*,
    workspace_service::app::app::read_apps_belong_to_workspace,
};
use anyhow::Context;
use chrono::Utc;
use flowy_net::{
    errors::{invalid_params, ServerError},
    response::FlowyResponse,
};
use flowy_user::entities::parser::UserId;
use flowy_workspace::{
    entities::{
        app::RepeatedApp,
        workspace::{
            parser::{WorkspaceDesc, WorkspaceId, WorkspaceName},
            Workspace,
        },
    },
    protobuf::{
        CreateWorkspaceParams,
        DeleteWorkspaceParams,
        QueryWorkspaceParams,
        UpdateWorkspaceParams,
    },
};
use sqlx::{postgres::PgArguments, PgPool, Postgres, Transaction};
use uuid::Uuid;

pub(crate) async fn create_workspace(
    pool: &PgPool,
    params: CreateWorkspaceParams,
) -> Result<FlowyResponse, ServerError> {
    let name = WorkspaceName::parse(params.get_name().to_owned()).map_err(invalid_params)?;
    let desc = WorkspaceDesc::parse(params.get_desc().to_owned()).map_err(invalid_params)?;
    let user_id = UserId::parse(params.user_id).map_err(invalid_params)?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create workspace")?;

    let uuid = uuid::Uuid::new_v4();
    let time = Utc::now();

    // TODO: use macro to fetch each field from struct
    let (sql, args) = SqlBuilder::create("workspace_table")
        .add_arg("id", uuid)
        .add_arg("name", name.as_ref())
        .add_arg("description", desc.as_ref())
        .add_arg("modified_time", &time)
        .add_arg("create_time", &time)
        .add_arg("user_id", user_id.as_ref())
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create workspace.")?;

    let workspace = Workspace {
        id: uuid.to_string(),
        name: name.as_ref().to_owned(),
        desc: desc.as_ref().to_owned(),
        apps: RepeatedApp::default(),
    };

    FlowyResponse::success().data(workspace)
}

pub(crate) async fn read_workspace(
    pool: &PgPool,
    params: QueryWorkspaceParams,
) -> Result<FlowyResponse, ServerError> {
    let workspace_id = check_workspace_id(params.get_workspace_id().to_owned())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read workspace")?;

    let (sql, args) = SqlBuilder::select("workspace_table")
        .add_field("*")
        .and_where_eq("id", workspace_id)
        .build()?;

    let table = sqlx::query_as_with::<Postgres, WorkspaceTable, PgArguments>(&sql, args)
        .fetch_one(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    let mut apps = RepeatedApp { items: vec![] };
    if params.read_apps {
        apps.items = read_apps_belong_to_workspace(&mut transaction, &table.id.to_string()).await?;
    }

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read workspace.")?;

    let mut workspace = Workspace::new(table.id.to_string(), table.name, table.description);
    workspace.apps = apps;

    FlowyResponse::success().data(workspace)
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

    let (sql, args) = SqlBuilder::update("workspace_table")
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

    let (sql, args) = SqlBuilder::delete("workspace_table")
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

fn check_workspace_id(id: String) -> Result<Uuid, ServerError> {
    let workspace_id = WorkspaceId::parse(id).map_err(invalid_params)?;
    let workspace_id = Uuid::parse_str(workspace_id.as_ref())?;
    Ok(workspace_id)
}
