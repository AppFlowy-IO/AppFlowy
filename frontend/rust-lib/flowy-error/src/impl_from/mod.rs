// #[cfg(feature = "adaptor_ot")]
// pub mod ot;

#[cfg(feature = "impl_from_serde")]
pub mod serde;

#[cfg(feature = "impl_from_dispatch_error")]
pub mod dispatch;

#[cfg(feature = "impl_from_reqwest")]
pub mod reqwest;

#[cfg(feature = "impl_from_sqlite")]
pub mod database;

#[cfg(any(
  feature = "impl_from_collab_document",
  feature = "impl_from_collab_folder",
  feature = "impl_from_collab_database"
))]
pub mod collab;

#[cfg(feature = "impl_from_collab_persistence")]
mod collab_persistence;

#[cfg(feature = "impl_from_appflowy_cloud")]
mod cloud;

#[cfg(feature = "impl_from_url")]
mod url;

#[cfg(feature = "impl_from_tantivy")]
mod tantivy;
