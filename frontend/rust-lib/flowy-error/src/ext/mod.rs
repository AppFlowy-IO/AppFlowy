#[cfg(feature = "adaptor_sync")]
pub mod sync;

#[cfg(feature = "adaptor_ot")]
pub mod ot;

#[cfg(feature = "adaptor_serde")]
pub mod serde;

#[cfg(feature = "adaptor_dispatch")]
pub mod dispatch;

#[cfg(feature = "adaptor_reqwest")]
pub mod reqwest;

#[cfg(feature = "adaptor_database")]
pub mod database;

#[cfg(feature = "adaptor_ws")]
pub mod ws;

#[cfg(feature = "adaptor_user")]
pub mod user;

#[cfg(feature = "adaptor_server_error")]
pub mod http_server;
