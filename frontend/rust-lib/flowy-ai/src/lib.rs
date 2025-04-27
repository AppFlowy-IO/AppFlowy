mod event_handler;
pub mod event_map;

pub mod ai_manager;
mod chat;
mod completion;
pub mod entities;
pub mod local_ai;

// #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
// pub mod mcp;

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub mod embeddings;
mod middleware;
pub mod notification;
pub mod offline;
mod protobuf;
mod stream_message;
mod util;
