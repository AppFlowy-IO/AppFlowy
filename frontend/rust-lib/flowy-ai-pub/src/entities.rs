use crate::cloud::CollabType;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

pub struct EmbeddingRecord {
  pub workspace_id: Uuid,
  pub object_id: Uuid,
  pub chunks: Vec<EmbeddedChunk>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UnindexedCollab {
  pub workspace_id: Uuid,
  pub object_id: Uuid,
  pub collab_type: CollabType,
  pub data: UnindexedData,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum UnindexedData {
  Text(String),
  Paragraphs(Vec<String>),
}

impl UnindexedData {
  #[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
  pub fn hash(&self) -> String {
    use twox_hash::xxhash64::Hasher;
    match self {
      UnindexedData::Text(text) => {
        let h = Hasher::oneshot(0, text.as_bytes());
        format!("{:016x}", h)
      },
      UnindexedData::Paragraphs(paragraphs) => {
        let combined = paragraphs.join("");
        let h = Hasher::oneshot(0, combined.as_bytes());
        format!("{:016x}", h)
      },
    }
  }
}

#[derive(Debug, Clone)]
pub struct EmbeddedChunk {
  pub fragment_id: String,
  pub object_id: String,
  pub content_type: i32,
  pub content: Option<String>,
  pub metadata: Option<String>,
  pub fragment_index: i32,
  pub embedder_type: i32,
  pub embeddings: Option<Vec<f32>>,
}

#[derive(Debug, Clone)]
pub struct SearchResult {
  pub oid: Uuid,
  pub content: String,
  pub metadata: Option<serde_json::Value>,
  pub score: f32,
}
