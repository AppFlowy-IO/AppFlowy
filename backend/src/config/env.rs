use std::env;

pub fn domain() -> String { env::var("DOMAIN").unwrap_or_else(|_| "localhost".to_string()) }

pub fn jwt_secret() -> String { env::var("JWT_SECRET").unwrap_or_else(|_| "my secret".into()) }

pub fn secret() -> String { env::var("SECRET_KEY").unwrap_or_else(|_| "0123".repeat(8)) }

pub fn use_https() -> bool { false }
