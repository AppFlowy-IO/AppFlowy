mod event_handler;
pub mod event_map;

pub mod ai_manager;
mod chat;
mod completion;
pub mod entities;
pub mod local_ai;

// #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
// pub mod mcp;

#[cfg(feature = "ai-tool")]
mod ai_tool;
#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub mod embeddings;
mod middleware;
mod model_select;
#[cfg(test)]
mod model_select_test;
pub mod notification;
pub mod offline;
mod protobuf;
mod search;
mod stream_message;
