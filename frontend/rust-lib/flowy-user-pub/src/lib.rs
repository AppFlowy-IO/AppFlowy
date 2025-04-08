pub mod cloud;
pub mod entities;
pub mod session;
pub mod workspace_service;

// anonymous user name
pub const DEFAULT_USER_NAME: fn() -> String = || "Anonymous".to_string();
