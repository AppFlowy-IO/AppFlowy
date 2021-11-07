#[cfg(feature = "flowy_client_sdk")]
pub use workspace_create::*;
#[cfg(feature = "flowy_client_sdk")]
pub use workspace_delete::*;
#[cfg(feature = "flowy_client_sdk")]
pub use workspace_query::*;
#[cfg(feature = "flowy_client_sdk")]
pub use workspace_update::*;
#[cfg(feature = "flowy_client_sdk")]
pub use workspace_user_detail::*;

#[cfg(feature = "flowy_client_sdk")]
mod workspace_create;
#[cfg(feature = "flowy_client_sdk")]
mod workspace_delete;
#[cfg(feature = "flowy_client_sdk")]
mod workspace_query;
#[cfg(feature = "flowy_client_sdk")]
mod workspace_update;
#[cfg(feature = "flowy_client_sdk")]
mod workspace_user_detail;

pub mod parser;
