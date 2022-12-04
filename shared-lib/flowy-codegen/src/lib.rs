#[cfg(feature = "proto_gen")]
pub mod protobuf_file;

#[cfg(feature = "dart_event")]
pub mod dart_event;

#[cfg(any(feature = "proto_gen", feature = "dart_event"))]
mod flowy_toml;

#[cfg(any(feature = "proto_gen", feature = "dart_event"))]
pub mod util;

#[derive(serde::Serialize, serde::Deserialize)]
pub struct ProtoCache {
    pub structs: Vec<String>,
    pub enums: Vec<String>,
}
