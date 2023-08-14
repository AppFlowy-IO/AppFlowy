pub mod cloud;
pub mod entities;

pub const DEFAULT_USER_NAME: fn() -> String = || "Me".to_string();
