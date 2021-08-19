use crate::errors::ServerError;
use flowy_user::protobuf::SignUpRequest;
use sqlx::PgPool;
use std::sync::Arc;

pub struct Auth {
    db_pool: Arc<PgPool>,
}

impl Auth {
    pub fn new(db_pool: Arc<PgPool>) -> Self { Self { db_pool } }

    pub fn handle_sign_up(&self, request: SignUpRequest) -> Result<(), ServerError> { Ok(()) }
}
