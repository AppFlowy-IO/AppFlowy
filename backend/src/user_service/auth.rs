use crate::{
    entities::{token::Token, user::UserTable},
    sqlx_ext::DBTransaction,
    user_service::{hash_password, verify_password},
    workspace_service::user_default::create_default_workspace,
};
use actix_identity::Identity;
use anyhow::Context;
use chrono::Utc;
use flowy_net::{
    errors::{ErrorCode, ServerError},
    response::FlowyResponse,
};
use flowy_user::{
    entities::parser::{UserEmail, UserName, UserPassword},
    protobuf::{SignInParams, SignInResponse, SignUpParams, SignUpResponse},
};
use sqlx::{PgPool, Postgres};

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
            let mut response_data = SignInResponse::default();
            response_data.set_uid(user.id.to_string());
            response_data.set_name(user.name);
            response_data.set_email(user.email);
            response_data.set_token(token.into());

            id.remember(response_data.token.clone());
            FlowyResponse::success().pb(response_data)
        },
        _ => Err(ServerError::password_not_match()),
    }
}

pub async fn register_user(
    pool: &PgPool,
    params: SignUpParams,
) -> Result<FlowyResponse, ServerError> {
    let name =
        UserName::parse(params.name).map_err(|e| ServerError::params_invalid().context(e))?;
    let email =
        UserEmail::parse(params.email).map_err(|e| ServerError::params_invalid().context(e))?;
    let password = UserPassword::parse(params.password)
        .map_err(|e| ServerError::params_invalid().context(e))?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to register user")?;

    let _ = is_email_exist(&mut transaction, email.as_ref()).await?;
    let response_data = insert_new_user(
        &mut transaction,
        name.as_ref(),
        email.as_ref(),
        password.as_ref(),
    )
    .await
    .context("Failed to insert user")?;

    let _ = create_default_workspace(&mut transaction, response_data.get_uid()).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to register user.")?;

    FlowyResponse::success().pb(response_data)
}

async fn is_email_exist(
    transaction: &mut DBTransaction<'_>,
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
    transaction: &mut DBTransaction<'_>,
    email: &str,
) -> Result<UserTable, ServerError> {
    let user = sqlx::query_as::<Postgres, UserTable>("SELECT * FROM user_table WHERE email = $1")
        .bind(email)
        .fetch_one(transaction)
        .await
        .map_err(|err| ServerError::internal().context(err))?;

    Ok(user)
}

async fn insert_new_user(
    transaction: &mut DBTransaction<'_>,
    name: &str,
    email: &str,
    password: &str,
) -> Result<SignUpResponse, ServerError> {
    let uuid = uuid::Uuid::new_v4();
    let password = hash_password(password)?;
    let _ = sqlx::query!(
        r#"
            INSERT INTO user_table (id, email, name, create_time, password)
            VALUES ($1, $2, $3, $4, $5)
        "#,
        uuid,
        email,
        name,
        Utc::now(),
        password,
    )
    .execute(transaction)
    .await
    .map_err(|e| ServerError::internal().context(e))?;

    let mut response = SignUpResponse::default();
    response.set_uid(uuid.to_string());
    response.set_name(name.to_string());
    response.set_email(email.to_string());

    Ok(response)
}
