use crate::{entities::workspace::WorkspaceTable, sqlx_ext::UpdateBuilder};
use anyhow::Context;
use chrono::Utc;
use flowy_net::{errors::ServerError, response::FlowyResponse};
use flowy_user::entities::parser::UserId;
use flowy_workspace::{
    entities::{
        app::RepeatedApp,
        workspace::{
            parser::{WorkspaceId, WorkspaceName},
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
use sqlx::{PgPool, Postgres};
use uuid::Uuid;

pub(crate) async fn create_workspace(
    pool: &PgPool,
    params: CreateWorkspaceParams,
) -> Result<FlowyResponse, ServerError> {
    let name = WorkspaceName::parse(params.get_name().to_owned())
        .map_err(|e| ServerError::params_invalid().context(e))?;
    let user_id = UserId::parse(params.get_user_id().to_owned())
        .map_err(|e| ServerError::params_invalid().context(e))?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create workspace")?;

    let uuid = uuid::Uuid::new_v4();
    let time = Utc::now();
    let _ = sqlx::query!(
        r#"
            INSERT INTO workspace_table (id, name, description, modified_time, create_time, user_id)
            VALUES ($1, $2, $3, $4, $5, $6)
        "#,
        uuid,
        name.as_ref(),
        params.desc,
        time,
        time,
        user_id.as_ref(),
    )
    .execute(&mut transaction)
    .await
    .map_err(|e| ServerError::internal().context(e))?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create workspace.")?;

    let workspace = Workspace {
        id: uuid.to_string(),
        name: name.as_ref().to_owned(),
        desc: params.desc,
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

    let uuid = Uuid::parse_str(workspace_id.as_ref())?;
    let table =
        sqlx::query_as::<Postgres, WorkspaceTable>("SELECT * FROM workspace_table WHERE id = $1")
            .bind(uuid)
            .fetch_one(&mut transaction)
            .await
            .map_err(|err| {
                //
                ServerError::internal().context(err)
            })?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read workspace.")?;

    let mut workspace = Workspace::new(table.id.to_string(), table.name, table.description);

    if params.get_read_apps() {
        workspace.apps = RepeatedApp { items: vec![] }
    }

    FlowyResponse::success().data(workspace)
}

pub(crate) async fn update_workspace(
    pool: &PgPool,
    params: UpdateWorkspaceParams,
) -> Result<FlowyResponse, ServerError> {
    let workspace_id = check_workspace_id(params.get_id().to_owned())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update workspace")?;

    let mut builder = UpdateBuilder::new("workspace_table");
    if params.has_name() {
        builder.add_argument("name", Some(params.get_name()));
    }
    if params.has_desc() {
        builder.add_argument("description", Some(params.get_desc()));
    }
    builder.add_argument("id", Some(workspace_id.as_ref()));
    let (sql, args) = builder.build();

    sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(|err| ServerError::internal().context(err))?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update workspace.")?;

    unimplemented!()
}

pub(crate) async fn delete_workspace(
    pool: &PgPool,
    params: DeleteWorkspaceParams,
) -> Result<FlowyResponse, ServerError> {
    let workspace_id = check_workspace_id(params.get_workspace_id().to_owned())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete workspace")?;

    let _ = sqlx::query(r#"DELETE FROM workspace_table where workspace_id = $1"#)
        .bind(workspace_id.as_ref())
        .execute(&mut transaction)
        .await
        .map_err(|e| ServerError::internal().context(e))?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete workspace.")?;

    Ok(FlowyResponse::success())
}

fn check_workspace_id(id: String) -> Result<WorkspaceId, ServerError> {
    let workspace_id =
        WorkspaceId::parse(id).map_err(|e| ServerError::params_invalid().context(e))?;
    Ok(workspace_id)
}
