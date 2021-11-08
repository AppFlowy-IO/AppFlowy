pub use auth::*;
pub use user_profile::*;

pub mod auth;
mod user_profile;

pub mod prelude {
    pub use crate::entities::{auth::*, user_profile::*};
}
