pub mod cloud;
pub mod entities;
pub mod folder_operation;

pub const DEFAULT_USER_NAME: fn() -> String = || "Me".to_string();
