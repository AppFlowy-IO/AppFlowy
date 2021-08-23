use crate::{
    entities::{token::Token, user::User},
    user_service::utils::{hash_password, verify_password},
};
use actix_identity::Identity;
use anyhow::Context;
use chrono::Utc;
use flowy_net::{
    errors::{ErrorCode, ServerError},
    response::FlowyResponse,
};
use flowy_user::{
    entities::{SignInResponse, SignUpResponse},
    prelude::parser::{UserEmail, UserPassword},
    protobuf::{SignInParams, SignUpParams},
};
use sqlx::{Error, PgPool, Postgres, Transaction};
use std::sync::Arc;

pub async fn sign_in(
    pool: &PgPool,
    params: SignInParams,
    id: Identity,
) -> Result<FlowyResponse, ServerError> {
    let email =
        UserEmail::parse(params.email).map_err(|e| ServerError::params_invalid().context(e))?;
    let password = UserPassword::parse(params.password)
        .map_err(|e| ServerError::params_invalid().context(e))?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to sign in")?;

    let user = read_user(&mut transaction, &email.0).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to sign in.")?;

    match verify_password(&password.0, &user.password) {
        Ok(true) => {
            let token = Token::create_token(&user)?;
            let data = SignInResponse {
                uid: user.id.to_string(),
                name: user.name,
                email: user.email,
                token: token.into(),
            };
            id.remember(data.token.clone());
            FlowyResponse::success(data)
        },
        _ => Err(ServerError::password_not_match()),
    }
}

pub async fn register_user(
    pool: &PgPool,
    params: SignUpParams,
) -> Result<FlowyResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to register user")?;

    let _ = is_email_exist(&mut transaction, &params.email).await?;
    let data = insert_user(&mut transaction, params)
        .await
        .context("Failed to insert user")?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to register user.")?;

    FlowyResponse::success(data)
}

async fn is_email_exist(
    transaction: &mut Transaction<'_, Postgres>,
    email: &str,
) -> Result<(), ServerError> {
    let result = sqlx::query(r#"SELECT email FROM user_table WHERE email = $1"#)
        .bind(email)
        .fetch_optional(transaction)
        .await
        .map_err(|err| ServerError::internal().context(err))?;

    match result {
        Some(_) => Err(ServerError {
            code: ErrorCode::EmailAlreadyExists,
            msg: format!("{} already exists", email),
        }),
        None => Ok(()),
    }
}

async fn read_user(
    transaction: &mut Transaction<'_, Postgres>,
    email: &str,
) -> Result<User, ServerError> {
    let user = sqlx::query_as::<Postgres, User>("SELECT * FROM user_table WHERE email = $1")
        .bind(email)
        .fetch_one(transaction)
        .await
        .map_err(|err| ServerError::internal().context(err))?;

    Ok(user)
}

async fn insert_user(
    transaction: &mut Transaction<'_, Postgres>,
    params: SignUpParams,
) -> Result<SignUpResponse, ServerError> {
    let uuid = uuid::Uuid::new_v4();
    let password = hash_password(&params.password)?;
    let _ = sqlx::query!(
        r#"
            INSERT INTO user_table (id, email, name, create_time, password)
            VALUES ($1, $2, $3, $4, $5)
        "#,
        uuid,
        params.email,
        params.name,
        Utc::now(),
        password,
    )
    .execute(transaction)
    .await
    .map_err(|e| ServerError::internal().context(e))?;

    let data = SignUpResponse {
        uid: uuid.to_string(),
        name: params.name,
        email: params.email,
    };

    Ok(data)
}
