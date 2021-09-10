use anyhow::Context;
use chrono::Utc;
use sqlx::{PgPool, Postgres};

use flowy_net::{
    errors::{invalid_params, ErrorCode, ServerError},
    response::FlowyResponse,
};
use flowy_user::{
    entities::parser::{UserEmail, UserName, UserPassword},
    protobuf::{
        SignInParams,
        SignInResponse,
        SignUpParams,
        SignUpResponse,
        UpdateUserParams,
        UserProfile,
    },
};

use crate::{
    entities::{token::Token, user::UserTable},
    service::{
        user_service::{hash_password, verify_password, LoggedUser},
        workspace_service::user_default::create_default_workspace,
    },
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};

use super::AUTHORIZED_USERS;

pub async fn sign_in(pool: &PgPool, params: SignInParams) -> Result<SignInResponse, ServerError> {
    let email =
        UserEmail::parse(params.email).map_err(|e| ServerError::params_invalid().context(e))?;
    let password = UserPassword::parse(params.password)
        .map_err(|e| ServerError::params_invalid().context(e))?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to sign in")?;

    let user = check_user_password(&mut transaction, email.as_ref(), password.as_ref()).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to sign in.")?;

    let token = Token::create_token(&user.id.to_string())?;
    let logged_user = LoggedUser::new(&user.id.to_string());

    let _ = AUTHORIZED_USERS.store_auth(logged_user, true)?;
    let mut response_data = SignInResponse::default();
    response_data.set_user_id(user.id.to_string());
    response_data.set_name(user.name);
    response_data.set_email(user.email);
    response_data.set_token(token.clone().into());

    Ok(response_data)
}

pub async fn sign_out(logged_user: LoggedUser) -> Result<FlowyResponse, ServerError> {
    let _ = AUTHORIZED_USERS.store_auth(logged_user, false)?;
    Ok(FlowyResponse::success())
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

    let logged_user = LoggedUser::new(&response_data.user_id);
    let _ = AUTHORIZED_USERS.store_auth(logged_user, true)?;
    let _ = create_default_workspace(&mut transaction, response_data.get_user_id()).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to register user.")?;

    FlowyResponse::success().pb(response_data)
}

pub(crate) async fn get_user_profile(
    pool: &PgPool,
    token: Token,
    logged_user: LoggedUser,
) -> Result<FlowyResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to get user detail")?;

    let id = logged_user.get_user_id()?;
    let user_table =
        sqlx::query_as::<Postgres, UserTable>("SELECT * FROM user_table WHERE id = $1")
            .bind(id)
            .fetch_one(&mut transaction)
            .await
            .map_err(|err| ServerError::internal().context(err))?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to get user detail.")?;

    // update the user active time
    let _ = AUTHORIZED_USERS.store_auth(logged_user, true)?;

    let mut user_profile = UserProfile::default();
    user_profile.set_id(user_table.id.to_string());
    user_profile.set_email(user_table.email);
    user_profile.set_name(user_table.name);
    user_profile.set_token(token.0);
    FlowyResponse::success().pb(user_profile)
}

pub(crate) async fn set_user_profile(
    pool: &PgPool,
    logged_user: LoggedUser,
    params: UpdateUserParams,
) -> Result<FlowyResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update user profile")?;

    let name = match params.has_name() {
        false => None,
        true => Some(
            UserName::parse(params.get_name().to_owned())
                .map_err(invalid_params)?
                .0,
        ),
    };

    let email = match params.has_email() {
        false => None,
        true => Some(
            UserEmail::parse(params.get_email().to_owned())
                .map_err(invalid_params)?
                .0,
        ),
    };

    let password = match params.has_password() {
        false => None,
        true => {
            let password =
                UserPassword::parse(params.get_password().to_owned()).map_err(invalid_params)?;
            let password = hash_password(password.as_ref())?;
            Some(password)
        },
    };

    let (sql, args) = SqlBuilder::update("user_table")
        .add_some_arg("name", name)
        .add_some_arg("email", email)
        .add_some_arg("password", password)
        .and_where_eq("id", &logged_user.get_user_id()?)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update user profile.")?;

    Ok(FlowyResponse::success())
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

async fn check_user_password(
    transaction: &mut DBTransaction<'_>,
    email: &str,
    password: &str,
) -> Result<UserTable, ServerError> {
    let user = sqlx::query_as::<Postgres, UserTable>("SELECT * FROM user_table WHERE email = $1")
        .bind(email)
        .fetch_one(transaction)
        .await
        .map_err(|err| ServerError::internal().context(err))?;

    match verify_password(&password, &user.password) {
        Ok(true) => Ok(user),
        _ => Err(ServerError::password_not_match()),
    }
}

async fn insert_new_user(
    transaction: &mut DBTransaction<'_>,
    name: &str,
    email: &str,
    password: &str,
) -> Result<SignUpResponse, ServerError> {
    let uuid = uuid::Uuid::new_v4();
    let token = Token::create_token(&uuid.to_string())?;
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
    response.set_user_id(uuid.to_string());
    response.set_name(name.to_string());
    response.set_email(email.to_string());
    response.set_token(token.into());

    Ok(response)
}
