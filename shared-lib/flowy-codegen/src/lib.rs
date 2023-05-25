#[cfg(feature = "proto_gen")]
pub mod protobuf_file;

#[cfg(feature = "dart_event")]
pub mod dart_event;

#[cfg(feature = "ts_event")]
pub mod ts_event;

#[cfg(any(feature = "proto_gen", feature = "dart_event", feature = "ts_event"))]
mod flowy_toml;

pub(crate) mod ast;
#[cfg(any(feature = "proto_gen", feature = "dart_event", feature = "ts_event"))]
pub mod util;

#[derive(serde::Serialize, serde::Deserialize)]
pub struct ProtoCache {
  pub structs: Vec<String>,
  pub enums: Vec<String>,
}
