use crate::embeddings::document_indexer::split_text_into_chunks;
use crate::embeddings::embedder::{Embedder, OllamaEmbedder};
use crate::embeddings::indexer::{EmbeddingModel, IndexerProvider};
use async_trait::async_trait;
use flowy_ai_pub::cloud::CollabType;
use flowy_ai_pub::entities::{RAG_IDS, SOURCE_ID};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite_vec::db::VectorSqliteDB;
use flowy_sqlite_vec::entities::{EmbeddedContent, SqliteEmbeddedDocument};
use futures::stream::{self, StreamExt};
use langchain_rust::llm::client::OllamaClient;
use langchain_rust::{
  schemas::Document,
  vectorstore::{VecStoreOptions, VectorStore},
};
use ollama_rs::generation::embeddings::request::{EmbeddingsInput, GenerateEmbeddingsRequest};
use serde_json::Value;
use std::collections::HashMap;
use std::error::Error;
use std::sync::{Arc, Weak};
use tracing::{error, trace, warn};
use uuid::Uuid;

#[derive(Clone)]
pub struct SqliteVectorStore {
  ollama: Weak<OllamaClient>,
  vector_db: Weak<VectorSqliteDB>,
  indexer_provider: Arc<IndexerProvider>,
}

impl SqliteVectorStore {
  pub fn new(ollama: Weak<OllamaClient>, vector_db: Weak<VectorSqliteDB>) -> Self {
    Self {
      ollama,
      vector_db,
      indexer_provider: IndexerProvider::new(),
    }
  }

  pub(crate) fn create_embedder(&self) -> Result<Embedder, FlowyError> {
    let ollama = self
      .ollama
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Ollama reference was dropped"))?;

    let embedder = Embedder::Ollama(OllamaEmbedder { ollama });
    Ok(embedder)
  }

  pub(crate) async fn select_all_embedded_documents(
    &self,
    workspace_id: &str,
    rag_ids: &[String],
  ) -> FlowyResult<Vec<SqliteEmbeddedDocument>> {
    // Get the vector database
    let vector_db = match self.vector_db.upgrade() {
      Some(db) => db,
      None => return Err(FlowyError::internal().with_context("Vector database not initialized")),
    };

    vector_db
      .select_all_embedded_documents(workspace_id, rag_ids)
      .await
      .map_err(|err| {
        FlowyError::internal().with_context(format!("Failed to select embedded documents: {}", err))
      })
  }

  pub async fn select_all_embedded_content(
    &self,
    workspace_id: &str,
    rag_ids: &[String],
    limit: usize,
  ) -> FlowyResult<Vec<EmbeddedContent>> {
    let vector_db = match self.vector_db.upgrade() {
      Some(db) => db,
      None => return Err(FlowyError::internal().with_context("Vector database not initialized")),
    };

    vector_db
      .select_all_embedded_content(workspace_id, rag_ids, limit)
      .await
      .map_err(|err| {
        FlowyError::internal().with_context(format!("Failed to select embedded content: {}", err))
      })
  }
}

#[async_trait]
impl VectorStore for SqliteVectorStore {
  type Options = VecStoreOptions<Value>;
  async fn add_documents(
    &self,
    docs: &[Document],
    _opt: &Self::Options,
  ) -> Result<Vec<String>, Box<dyn Error>> {
    let vector_db = match self.vector_db.upgrade() {
      Some(db) => db,
      None => return Err("Vector database not initialized".into()),
    };

    let embedder = self.create_embedder()?;

    let indexer = self
      .indexer_provider
      .indexer_for(CollabType::Document)
      .ok_or_else(|| Box::<dyn Error>::from("Failed to get indexer for Document"))?;

    // Parse documents and filter out invalid ones early
    let documents = docs
      .iter()
      .filter_map(|v| {
        let workspace_id = match v.metadata.get("workspace_id") {
          Some(value) => value.as_str().and_then(|s| Uuid::parse_str(s).ok()),
          None => None,
        }?;

        let object_id = match v.metadata.get(SOURCE_ID) {
          Some(value) => value.as_str().and_then(|s| Uuid::parse_str(s).ok()),
          None => None,
        }?;

        Some((workspace_id, object_id, v.page_content.clone()))
      })
      .collect::<Vec<(Uuid, Uuid, String)>>();

    let concurrency_limit = 4;
    let document_ids = stream::iter(documents)
      .map(|(workspace_id, object_id, paragraph)| {
        // Clone values that need to be moved into the async block
        let object_id_str = object_id.to_string();
        let workspace_id_str = workspace_id.to_string();
        let vector_db_clone = vector_db.clone();
        let embedder_clone = embedder.clone();
        let indexer_clone = indexer.clone();

        async move {
          let chunks_result = split_text_into_chunks(
            &object_id_str,
            vec![paragraph],
            EmbeddingModel::NomicEmbedText,
            2000,
            200,
          );

          match chunks_result {
            Ok(chunks) => match indexer_clone.embed(&embedder_clone, chunks).await {
              Ok(chunks) => {
                if let Err(e) = vector_db_clone
                  .upsert_collabs_embeddings(&workspace_id_str, &object_id_str, chunks)
                  .await
                {
                  error!(
                    "[Embedding] Failed to upsert document `{}`: {}",
                    object_id_str, e
                  );
                  return None;
                }

                Some(object_id_str)
              },
              Err(err) => {
                error!(
                  "[Embedding] Failed to embed document `{}`: {}",
                  object_id_str, err
                );
                None
              },
            },
            Err(err) => {
              error!(
                "[Embedding] Failed to split document `{}`: {}",
                object_id_str, err
              );
              None
            },
          }
        }
      })
      .buffer_unordered(concurrency_limit)
      .filter_map(|result| async move { result })
      .collect()
      .await;

    Ok(document_ids)
  }

  async fn similarity_search(
    &self,
    query: &str,
    limit: usize,
    opt: &Self::Options,
  ) -> Result<Vec<Document>, Box<dyn Error>> {
    // Extract rag_ids from filters
    let rag_ids = opt
      .filters
      .as_ref()
      .and_then(|filters| filters.get(RAG_IDS))
      .and_then(|value| value.as_array())
      .map(|array| {
        array
          .iter()
          .filter_map(|item| item.as_str().map(String::from))
          .collect::<Vec<_>>()
      })
      .unwrap_or_default();

    // Extract workspace_id from filters
    let workspace_id = opt
      .filters
      .as_ref()
      .and_then(|filters| filters.get("workspace_id"))
      .and_then(|value| value.as_str())
      .and_then(|s| Uuid::parse_str(s).ok());

    // Return empty result if workspace_id is missing
    let workspace_id = match workspace_id {
      Some(id) => id.to_string(),
      None => {
        warn!("[VectorStore] Missing workspace_id in filters. Returning empty result.");
        return Ok(Vec::new());
      },
    };

    // Get the vector database
    let vector_db = match self.vector_db.upgrade() {
      Some(db) => db,
      None => return Err("Vector database not initialized".into()),
    };

    // Create embedder and generate embedding for query
    let embedder = self.create_embedder()?;
    let request = GenerateEmbeddingsRequest::new(
      embedder.model().name().to_string(),
      EmbeddingsInput::Single(query.to_string()),
    );

    let embedding = match embedder.embed(request).await {
      Ok(result) => result.embeddings,
      Err(e) => return Err(Box::new(e)),
    };

    if embedding.is_empty() {
      return Ok(Vec::new());
    }

    let score_threshold = opt.score_threshold.unwrap_or(0.4);
    debug_assert!(embedding.len() == 1);
    let query_embedding = embedding.first().unwrap();

    // Perform similarity search in the database
    let results = vector_db
      .search_with_score(
        &workspace_id,
        &rag_ids,
        query_embedding,
        limit as i32,
        score_threshold,
      )
      .await?;

    trace!(
      "[VectorStore] Found {} results for query:{}, rag_ids: {:?}, score_threshold: {}",
      results.len(),
      query,
      rag_ids,
      score_threshold
    );

    // Convert results to Documents
    let documents = results
      .into_iter()
      .map(|result| {
        let mut metadata = HashMap::new();

        if let Some(map) = result.metadata.as_ref().and_then(|v| v.as_object()) {
          for (key, value) in map {
            metadata.insert(key.clone(), value.clone());
          }
        }

        Document::new(result.content).with_metadata(metadata)
      })
      .collect();

    Ok(documents)
  }
}
