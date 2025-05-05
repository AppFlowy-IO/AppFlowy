use crate::embeddings::embedder::{Embedder, OllamaEmbedder};
use crate::embeddings::indexer::IndexerProvider;
use crate::search::summary::{summarize_documents, LLMDocument};
use flowy_ai_pub::cloud::search_dto::{
  SearchContentType, SearchDocumentResponseItem, SearchResult, SearchSummaryResult, Summary,
};
use flowy_ai_pub::entities::{EmbeddingRecord, UnindexedCollab, UnindexedData};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::internal::derives::multiconnection::chrono::Utc;
use flowy_sqlite_vec::db::VectorSqliteDB;
use ollama_rs::generation::embeddings::request::{EmbeddingsInput, GenerateEmbeddingsRequest};
use ollama_rs::Ollama;
use std::sync::{Arc, Weak};
use tokio::select;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tokio::sync::{broadcast, mpsc};
use tracing::{debug, error, info, trace, warn};
use uuid::Uuid;

type UnindexedCollabContext = UnindexedCollab;

pub struct EmbeddingScheduler {
  indexer_provider: Arc<IndexerProvider>,
  write_embedding_tx: UnboundedSender<EmbeddingRecord>,
  generate_embedding_tx: mpsc::Sender<UnindexedCollab>,
  ollama: Arc<Ollama>,
  vector_db: Arc<VectorSqliteDB>,
  pub(crate) stop_tx: tokio::sync::broadcast::Sender<()>,
}

impl EmbeddingScheduler {
  pub fn new(
    ollama: Arc<Ollama>,
    vector_db: Arc<VectorSqliteDB>,
  ) -> FlowyResult<Arc<EmbeddingScheduler>> {
    let indexer_provider = IndexerProvider::new();
    let (write_embedding_tx, write_embedding_rx) = unbounded_channel::<EmbeddingRecord>();
    let (generate_embedding_tx, gen_embedding_rx) = mpsc::channel::<UnindexedCollabContext>(100);
    let (stop_tx, _) = broadcast::channel::<()>(1);

    let this = Arc::new(Self {
      indexer_provider,
      write_embedding_tx,
      generate_embedding_tx,
      ollama,
      vector_db,
      stop_tx,
    });

    let weak_this = Arc::downgrade(&this);
    let stop_rx = this.stop_tx.subscribe();
    tokio::spawn(spawn_generate_embeddings(
      gen_embedding_rx,
      weak_this.clone(),
      stop_rx,
    ));

    let weak_this = Arc::downgrade(&this);
    let stop_rx = this.stop_tx.subscribe();
    tokio::spawn(spawn_write_embeddings(
      write_embedding_rx,
      weak_this,
      stop_rx,
    ));

    Ok(this)
  }

  pub(crate) fn create_embedder(&self) -> Result<Embedder, FlowyError> {
    let embedder = Embedder::Ollama(OllamaEmbedder {
      ollama: self.ollama.clone(),
    });
    Ok(embedder)
  }

  pub async fn index_collab(&self, data: UnindexedCollab) -> FlowyResult<()> {
    trace!("[Embedding] got {} unindexd data", data.object_id);
    if let Err(err) = self.generate_embedding_tx.send(data).await {
      error!("[Embedding] error generating embedding: {}", err);
    }
    Ok(())
  }

  pub async fn delete_collab(&self, workspace_id: &Uuid, object_id: &Uuid) -> FlowyResult<()> {
    self
      .vector_db
      .delete_collab(&workspace_id.to_string(), &object_id.to_string())
      .await
      .map_err(|err| {
        error!("[Embedding] Failed to delete collab: {}", err);
        FlowyError::new(ErrorCode::LocalEmbeddingNotReady, "Failed to delete collab")
      })?;
    Ok(())
  }

  pub async fn search(
    &self,
    workspace_id: &Uuid,
    query: &str,
  ) -> FlowyResult<Vec<SearchDocumentResponseItem>> {
    let embedder = self.create_embedder()?;
    let request = GenerateEmbeddingsRequest::new(
      embedder.model().name().to_string(),
      EmbeddingsInput::Single(query.to_string()),
    );

    let resp = embedder.embed(request).await?;
    match resp.embeddings.first() {
      None => Ok(vec![]),
      Some(query_embed) => {
        let result = self
          .vector_db
          .search_with_score(&workspace_id.to_string(), vec![], query_embed, 10, 0.4)
          .await
          .map_err(|err| {
            error!("[Embedding] Failed to search: {}", err);
            FlowyError::new(ErrorCode::LocalEmbeddingNotReady, "Failed to search")
          })?;

        let rows = result
          .into_iter()
          .map(|v| SearchDocumentResponseItem {
            object_id: v.oid,
            workspace_id: *workspace_id,
            score: 1.0,
            content_type: Some(SearchContentType::PlainText),
            content: v.content,
            preview: None,
            created_by: "".to_string(),
            created_at: Utc::now(),
          })
          .collect::<Vec<_>>();

        Ok(rows)
      },
    }
  }

  pub async fn generate_summary(
    &self,
    question: &str,
    model_name: &str,
    search_results: Vec<SearchResult>,
  ) -> FlowyResult<SearchSummaryResult> {
    if search_results.is_empty() {
      return Ok(SearchSummaryResult { summaries: vec![] });
    }

    let docs = search_results
      .into_iter()
      .map(|v| LLMDocument {
        content: v.content,
        object_id: v.object_id,
      })
      .collect::<Vec<_>>();
    let resp = summarize_documents(&self.ollama, question, model_name, docs)
      .await
      .map_err(|err| {
        error!("[Embedding] Failed to generate summary: {}", err);
        FlowyError::new(
          ErrorCode::LocalEmbeddingNotReady,
          "Failed to generate summary",
        )
      })?;

    let summaries = resp
      .summaries
      .into_iter()
      .flat_map(|s| {
        if s.content.is_empty() {
          None
        } else {
          Some(Summary {
            content: s.content,
            highlights: s.highlights,
            sources: s.sources,
          })
        }
      })
      .collect::<Vec<_>>();
    Ok(SearchSummaryResult { summaries })
  }
}

const EMBEDDING_RECORD_BUFFER_SIZE: usize = 10;

pub async fn spawn_write_embeddings(
  mut rx: UnboundedReceiver<EmbeddingRecord>,
  scheduler: Weak<EmbeddingScheduler>,
  mut stop_rx: broadcast::Receiver<()>,
) {
  let mut buf = Vec::with_capacity(EMBEDDING_RECORD_BUFFER_SIZE);

  loop {
    select! {
      // Shutdown signal arrives
      _ = stop_rx.recv() => {
          info!("Received stop signal; shutting down embedding writer");
          break;
      }
      // Next batch from the input channel
      n = rx.recv_many(&mut buf, EMBEDDING_RECORD_BUFFER_SIZE) => {
        // channel closed
        if n == 0 {
          info!("Input channel closed; stopping write embeddings");
          break;
        }

        // upgrade scheduler reference
        let scheduler = match scheduler.upgrade() {
          Some(db) => db,
          None => {
              error!("EmbeddingScheduler dropped; stopping write embeddings");
              break;
          }
        };

        // drain and process exactly `n` records
        let records = buf.drain(..n).collect::<Vec<_>>();
        for record in records {
          debug!("[Embedding] Writing {} chunks for {}", record.chunks.len(), record.object_id);
          match scheduler
              .vector_db
              .upsert_collabs_embeddings(&record.workspace_id.to_string(), &record.object_id.to_string(), record.chunks)
              .await
          {
            Ok(_) => trace!("[Embedding] Successfully wrote embeddings for {}", record.object_id),
            Err(err) => error!("[Embedding] Failed to write embeddings for {}: {}", record.object_id, err),
          }
        }
      }
    }
  }

  info!("spawn_write_embeddings exited");
}

async fn spawn_generate_embeddings(
  mut rx: mpsc::Receiver<UnindexedCollab>,
  scheduler: Weak<EmbeddingScheduler>,
  mut stop_rx: broadcast::Receiver<()>,
) {
  let mut buf = Vec::with_capacity(EMBEDDING_RECORD_BUFFER_SIZE);
  loop {
    select! {
      _ = stop_rx.recv() => {
        info!("Received stop signal; shutting down embedding writer");
        break;
      }
      n = rx.recv_many(&mut buf, EMBEDDING_RECORD_BUFFER_SIZE) => {
        let scheduler = match scheduler.upgrade() {
          Some(scheduler) => scheduler,
          None => {
            info!("[Embedding] Failed to upgrade scheduler connection, break loop");
            break;
          },
        };
        if n == 0 {
          info!("[Embedding] Stop generating embeddings");
          break;
        }

        let records = buf.drain(..n).collect::<Vec<_>>();
        let indexer_provider = scheduler.indexer_provider.clone();
        let write_embedding_tx = scheduler.write_embedding_tx.clone();
        let embedder = scheduler.create_embedder();

        match embedder {
          Ok(embedder) => {
            let params: Vec<_> = records.iter().map(|r| r.object_id.to_string()).collect();
            let existing_embeddings = scheduler
                .vector_db
                .select_collabs_fragment_ids(&params)
                .await
                .unwrap_or_else(|err| {
                  error!("[Embedding] failed to get existing embeddings: {}", err);
                  Default::default()
                });

            for record in records {
              if let Some(indexer) = indexer_provider.indexer_for(record.collab_type) {
                let paragraphs = match record.data {
                  UnindexedData::Paragraphs(paragraphs) => paragraphs,
                  UnindexedData::Text(text) => text.split('\n').map(|s| s.to_string()).collect(),
                };
                let embedder = embedder.clone();
                match indexer.create_embedded_chunks_from_text(
                  record.object_id,
                  paragraphs,
                  embedder.model(),
                ) {
                  Ok(mut chunks) => {
                    if let Some(fragment_ids) = existing_embeddings.get(&record.object_id) {
                      for chunk in chunks.iter_mut() {
                        if fragment_ids.contains(&chunk.fragment_id) {
                          chunk.content = None;
                        }
                      }
                    }

                    if chunks.iter().all(|c| c.content.is_none()) {
                      trace!(
                        "[Embedding] skip generating embeddings for collab: {}",
                        record.object_id
                      );
                      continue;
                    }

                    let result = indexer.embed(&embedder, chunks).await;
                    match result {
                      Ok(chunks) => {
                        let record = EmbeddingRecord {
                          workspace_id: record.workspace_id,
                          object_id: record.object_id,
                          chunks,
                        };
                        if let Err(err) = write_embedding_tx.send(record) {
                          error!("Failed to send embedding record: {}", err);
                        }
                      },
                      Err(err) => {
                        error!(
                          "[Embedding] Failed to create embeddings content for collab: {}, error:{}",
                          record.object_id, err
                        );
                      },
                    }
                  },
                  Err(err) => {
                    warn!(
                      "Failed to create embedded chunks for collab: {}, error:{}",
                      record.object_id, err
                    );
                    continue;
                  },
                }
              }
            }
          },
          Err(err) => error!("[Embedding] Failed to create embedder: {}", err),
        }
      }
    }
  }
  info!("spawn_generate_embeddings exited");
}
