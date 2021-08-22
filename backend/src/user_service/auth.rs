use chrono::Utc;
use flowy_net::response::{ServerCode, ServerError};
use flowy_user::{entities::SignUpResponse, protobuf::SignUpParams};
use sqlx::PgPool;
use std::sync::Arc;

pub struct Auth {
    db_pool: Arc<PgPool>,
}

impl Auth {
    pub fn new(db_pool: Arc<PgPool>) -> Self { Self { db_pool } }

    pub async fn sign_up(&self, params: SignUpParams) -> Result<SignUpResponse, ServerError> {
        // email exist?
        // generate user id
        let result = sqlx::query!(
            r#"
            INSERT INTO user_table (id, email, name, create_time, password)
            VALUES ($1, $2, $3, $4, $5)
        "#,
            uuid::Uuid::new_v4(),
            params.email,
            params.name,
            Utc::now(),
            "123".to_string()
        )
        .execute(self.db_pool.as_ref())
        .await;

        let response = SignUpResponse {
            uid: "".to_string(),
            name: "".to_string(),
            email: "".to_string(),
        };
        Ok(response)
    }

    pub fn is_email_exist(&self, email: &str) -> bool { true }
}
