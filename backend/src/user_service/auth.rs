use anyhow::Context;
use chrono::Utc;
use flowy_net::response::{Code, FlowyResponse, ServerError};
use flowy_user::{entities::SignUpResponse, protobuf::SignUpParams};
use sqlx::{Error, PgPool, Postgres, Transaction};
use std::sync::Arc;

pub async fn sign_up(pool: &PgPool, params: SignUpParams) -> Result<FlowyResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection from the pool")?;

    let _ = is_email_exist(&mut transaction, &params.email).await?;

    let data = insert_user(&mut transaction, params)
        .await
        .context("Failed to insert user")?;

    let response = FlowyResponse::success(data).context("Failed to generate response")?;

    Ok(response)
}

async fn is_email_exist(
    transaction: &mut Transaction<'_, Postgres>,
    email: &str,
) -> Result<(), ServerError> {
    let result = sqlx::query!(
        r#"SELECT email FROM user_table WHERE email = $1"#,
        email.to_string()
    )
    .fetch_optional(transaction)
    .await
    .map_err(ServerError::internal)?;

    match result {
        Some(_) => Err(ServerError {
            code: Code::EmailAlreadyExists,
            msg: format!("{} already exists", email),
        }),
        None => Ok(()),
    }
}

async fn insert_user(
    transaction: &mut Transaction<'_, Postgres>,
    params: SignUpParams,
) -> Result<SignUpResponse, ServerError> {
    let uuid = uuid::Uuid::new_v4();
    let result = sqlx::query!(
        r#"
            INSERT INTO user_table (id, email, name, create_time, password)
            VALUES ($1, $2, $3, $4, $5)
        "#,
        uuid,
        params.email,
        params.name,
        Utc::now(),
        "123".to_string()
    )
    .execute(transaction)
    .await
    .map_err(ServerError::internal)?;

    let data = SignUpResponse {
        uid: uuid.to_string(),
        name: params.name,
        email: params.email,
    };

    Ok(data)
}
