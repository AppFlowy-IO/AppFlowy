use backend_service::errors::{ErrorCode, ServerError};
use bcrypt::{hash, verify, DEFAULT_COST};

#[allow(dead_code)]
pub fn uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}

pub fn hash_password(plain: &str) -> Result<String, ServerError> {
    let hashing_cost = std::env::var("HASH_COST")
        .ok()
        .and_then(|c| c.parse().ok())
        .unwrap_or(DEFAULT_COST);

    hash(plain, hashing_cost).map_err(|e| ServerError::internal().context(e))
}

// The Source is the password user enter. The hash is the source after hashing.
// let source = "123";
// let hash = hash_password(source).unwrap();
//
// verify_password(source, hash)
pub fn verify_password(source: &str, hash: &str) -> Result<bool, ServerError> {
    match verify(source, hash) {
        Ok(true) => Ok(true),
        _ => Err(ServerError::new(
            "Username and password don't match".to_string(),
            ErrorCode::PasswordNotMatch,
        )),
    }
}
