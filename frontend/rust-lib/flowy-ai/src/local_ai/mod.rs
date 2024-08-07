pub mod local_llm_chat;
pub mod local_llm_resource;
mod model_request;

mod path;
pub mod stream_util;
#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub mod watch;
