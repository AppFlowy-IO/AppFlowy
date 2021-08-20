use flowy_net::errors::ServerError;
use flowy_user::protobuf::SignUpParams;
use sqlx::PgPool;
use std::sync::Arc;

pub struct Auth {
    db_pool: Arc<PgPool>,
}

impl Auth {
    pub fn new(db_pool: Arc<PgPool>) -> Self { Self { db_pool } }

    pub fn sign_up(&self, params: SignUpParams) -> Result<(), ServerError> { Ok(()) }
}
