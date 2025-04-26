use crate::embeddings::document_indexer::DocumentIndexer;
use crate::embeddings::embedder::Embedder;
use flowy_ai_pub::cloud::CollabType;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use uuid::Uuid;

#[derive(Serialize, Deserialize, Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum EmbeddingModel {
  NomicEmbedText,
}

impl EmbeddingModel {
  pub fn name(&self) -> &'static str {
    match self {
      EmbeddingModel::NomicEmbedText => "nomic-embed-text",
    }
  }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EmbeddedChunk {
  pub fragment_id: String,
  pub object_id: String,
  pub content: Option<String>,
  pub embedding: Option<Vec<f32>>,
  pub metadata: serde_json::Value,
  pub fragment_index: i32,
  pub embedded_type: i16,
  pub embeddings: Option<Vec<f32>>,
}

#[async_trait]
pub trait Indexer: Send + Sync {
  fn create_embedded_chunks_from_text(
    &self,
    object_id: Uuid,
    paragraphs: Vec<String>,
    model: EmbeddingModel,
  ) -> Result<Vec<EmbeddedChunk>, FlowyError>;

  async fn embed(
    &self,
    embedder: &Embedder,
    chunks: Vec<EmbeddedChunk>,
  ) -> Result<Vec<EmbeddedChunk>, FlowyError>;
}

/// A structure responsible for resolving different [Indexer] types for different [CollabType]s,
/// including access permission checks for the specific workspaces.
pub struct IndexerProvider {
  indexer_cache: HashMap<CollabType, Arc<dyn Indexer>>,
}

impl IndexerProvider {
  pub fn new() -> Arc<Self> {
    let mut cache: HashMap<CollabType, Arc<dyn Indexer>> = HashMap::new();
    cache.insert(CollabType::Document, Arc::new(DocumentIndexer));
    Arc::new(Self {
      indexer_cache: cache,
    })
  }

  /// Returns indexer for a specific type of [Collab] object.
  /// If collab of given type is not supported or workspace it belongs to has indexing disabled,
  /// returns `None`.
  pub fn indexer_for(&self, collab_type: CollabType) -> Option<Arc<dyn Indexer>> {
    self.indexer_cache.get(&collab_type).cloned()
  }

  pub fn is_indexing_enabled(&self, collab_type: CollabType) -> bool {
    self.indexer_cache.contains_key(&collab_type)
  }
}
