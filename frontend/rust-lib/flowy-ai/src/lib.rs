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

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub use embeddings::store::SqliteVectorStore;

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
pub use mock::SqliteVectorStore;

#[cfg(all(
  not(target_os = "windows"),
  not(target_os = "macos"),
  not(target_os = "linux")
))]
#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
mod mock {
  use async_trait::async_trait;
  use langchain_rust::schemas::Document;
  use langchain_rust::vectorstore::{VecStoreOptions, VectorStore};
  use serde_json::Value;
  use std::error::Error;
  #[derive(Clone)]
  pub struct SqliteVectorStore;
  #[async_trait]
  impl VectorStore for SqliteVectorStore {
    type Options = VecStoreOptions<Value>;
    async fn add_documents(
      &self,
      docs: &[Document],
      _opt: &Self::Options,
    ) -> Result<Vec<String>, Box<dyn Error>> {
      Ok(vec![])
    }

    async fn similarity_search(
      &self,
      query: &str,
      limit: usize,
      opt: &Self::Options,
    ) -> Result<Vec<Document>, Box<dyn Error>> {
      Ok(vec![])
    }
  }
}

mod middleware;
mod model_select;
#[cfg(test)]
mod model_select_test;
pub mod notification;
pub mod offline;
mod protobuf;
mod search;
mod stream_message;
