pub mod cloud;
pub mod entities;
pub mod session;
pub mod workspace_service;

pub const DEFAULT_USER_NAME: fn() -> String = || "Me".to_string();
