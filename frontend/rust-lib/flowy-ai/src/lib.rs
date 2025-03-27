mod event_handler;
pub mod event_map;

pub mod ai_manager;
mod chat;
mod completion;
pub mod entities;
mod local_ai;

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub mod mcp;

mod middleware;
pub mod notification;
mod persistence;
mod protobuf;
mod stream_message;
mod util;
