use bcrypt::{hash, verify, BcryptError, DEFAULT_COST};
use flowy_net::errors::{ErrorCode, Kind, ServerError};
use jsonwebtoken::Algorithm;

pub fn uuid() -> String { uuid::Uuid::new_v4().to_string() }

pub fn hash_password(plain: &str) -> Result<String, ServerError> {
    let hashing_cost = std::env::var("HASH_COST")
        .ok()
        .and_then(|c| c.parse().ok())
        .unwrap_or(DEFAULT_COST);

    hash(plain, hashing_cost).map_err(|e| ServerError::internal().context(e))
}

pub fn verify_password(source: &str, hash: &str) -> Result<bool, ServerError> {
    match verify(source, hash) {
        Ok(true) => Ok(true),
        _ => Err(ServerError::new(
            "Username and password don't match".to_string(),
            ErrorCode::PasswordNotMatch,
            Kind::User,
        )),
    }
}
