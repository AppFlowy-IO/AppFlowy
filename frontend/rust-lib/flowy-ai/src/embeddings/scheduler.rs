use crate::embeddings::embedder::{Embedder, OllamaEmbedder};
use crate::embeddings::indexer::IndexerProvider;
use crate::search::summary::{summarize_documents, LLMDocument};
use arc_swap::ArcSwapOption;
use flowy_ai_pub::cloud::search_dto::{
  SearchContentType, SearchDocumentResponseItem, SearchResult, SearchSummaryResult, Summary,
};
use flowy_ai_pub::entities::{EmbeddingRecord, UnindexedCollab, UnindexedData};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::internal::derives::multiconnection::chrono::Utc;
use flowy_sqlite_vec::db::VectorSqliteDB;
use lib_infra::util::get_operating_system;
use ollama_rs::generation::embeddings::request::{EmbeddingsInput, GenerateEmbeddingsRequest};
use ollama_rs::Ollama;
use std::path::PathBuf;
use std::sync::{Arc, OnceLock, Weak};
use tokio::sync::mpsc;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tracing::{debug, error, info, trace, warn};
use uuid::Uuid;

pub struct EmbedContext {
  ollama: ArcSwapOption<Ollama>,
  vector_db: ArcSwapOption<VectorSqliteDB>,
  scheduler: ArcSwapOption<EmbeddingScheduler>,
}

impl EmbedContext {
  pub fn shared() -> &'static Arc<EmbedContext> {
    static INSTANCE: OnceLock<Arc<EmbedContext>> = OnceLock::new();
    INSTANCE.get_or_init(|| {
      Arc::new(EmbedContext {
        ollama: ArcSwapOption::empty(),
        vector_db: ArcSwapOption::empty(),
        scheduler: Default::default(),
      })
    })
  }

  pub fn init_vector_db(&self, db_path: PathBuf) {
    let sys = get_operating_system();
    if !sys.is_desktop() {
      warn!("[Embedding] Vector db is not supported on {:?}", sys);
      return;
    }

    info!("Initializing vector db");
    match VectorSqliteDB::new(db_path.clone()) {
      Ok(db) => {
        info!("[Embedding] Vector db created at: {:?}", db_path);
        self.vector_db.store(Some(Arc::new(db)));
        self.try_create_scheduler();
      },
      Err(err) => {
        error!("[Embedding] Failed to create vector db: {}", err);
      },
    }
  }

  pub fn set_ollama(&self, ollama: Arc<Ollama>) {
    self.ollama.store(Some(ollama.clone()));
    self.try_create_scheduler();
  }

  pub fn get_scheduler(&self) -> FlowyResult<Arc<EmbeddingScheduler>> {
    self.scheduler.load_full().ok_or_else(|| {
      FlowyError::new(
        ErrorCode::LocalEmbeddingNotReady,
        "Local embedding is not ready. Please check if the Ollama and vector db are initialized.",
      )
    })
  }

  fn try_create_scheduler(&self) {
    if let (Some(ollama), Some(vector_db)) = (self.ollama.load_full(), self.vector_db.load_full()) {
      info!("[Embedding] Creating scheduler");
      match EmbeddingScheduler::new(ollama, vector_db) {
        Ok(s) => {
          info!("[Embedding] create scheduler successfully");
          self.scheduler.store(Some(s));
        },
        Err(err) => error!("[Embedding] Failed to create scheduler: {}", err),
      }
    }
  }
}

pub struct EmbeddingScheduler {
  indexer_provider: Arc<IndexerProvider>,
  write_embedding_tx: UnboundedSender<EmbeddingRecord>,
  generate_embedding_tx: mpsc::Sender<UnindexedCollab>,
  ollama: Arc<Ollama>,
  vector_db: Arc<VectorSqliteDB>,
}

impl EmbeddingScheduler {
  pub fn new(
    ollama: Arc<Ollama>,
    vector_db: Arc<VectorSqliteDB>,
  ) -> FlowyResult<Arc<EmbeddingScheduler>> {
    let indexer_provider = IndexerProvider::new();
    let (write_embedding_tx, write_embedding_rx) = unbounded_channel::<EmbeddingRecord>();
    let (generate_embedding_tx, gen_embedding_rx) = mpsc::channel::<UnindexedCollab>(100);

    let this = Arc::new(Self {
      indexer_provider,
      write_embedding_tx,
      generate_embedding_tx,
      ollama,
      vector_db,
    });

    let weak_this = Arc::downgrade(&this);
    tokio::spawn(spawn_generate_embeddings(
      gen_embedding_rx,
      weak_this.clone(),
    ));

    let weak_this = Arc::downgrade(&this);
    tokio::spawn(spawn_write_embeddings(write_embedding_rx, weak_this));

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
          .search(query_embed, 10)
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
      .map(|s| Summary {
        content: s.content,
        highlights: s.highlights,
        sources: s.sources,
      })
      .collect::<Vec<_>>();
    Ok(SearchSummaryResult { summaries })
  }
}

const EMBEDDING_RECORD_BUFFER_SIZE: usize = 10;

pub async fn spawn_write_embeddings(
  mut rx: UnboundedReceiver<EmbeddingRecord>,
  scheduler: Weak<EmbeddingScheduler>,
) {
  let mut buf = Vec::with_capacity(EMBEDDING_RECORD_BUFFER_SIZE);
  loop {
    let n = rx.recv_many(&mut buf, EMBEDDING_RECORD_BUFFER_SIZE).await;
    if n == 0 {
      info!("Stop writing embeddings");
      break;
    }

    let scheduler = match scheduler.upgrade() {
      Some(db) => db,
      None => {
        error!("Failed to upgrade db connection");
        break;
      },
    };

    let records = buf.drain(..n).collect::<Vec<_>>();
    for record in records.into_iter() {
      debug!(
        "[Embedding] write collab to disk:{} embeddings",
        record.object_id,
      );

      match scheduler
        .vector_db
        .upsert_collabs_embeddings(&record.object_id.to_string(), record.chunks)
        .await
      {
        Ok(_) => {
          trace!(
            "[Embedding] Successfully wrote collab:{} embeddings to db",
            record.object_id
          );
        },
        Err(err) => {
          error!(
            "[Embedding] Failed to write collab:{} embeddings to db: {}",
            record.object_id, err
          );
        },
      }
    }
  }
}

async fn spawn_generate_embeddings(
  mut rx: mpsc::Receiver<UnindexedCollab>,
  scheduler: Weak<EmbeddingScheduler>,
) {
  let mut buf = Vec::with_capacity(EMBEDDING_RECORD_BUFFER_SIZE);
  loop {
    let n = rx.recv_many(&mut buf, EMBEDDING_RECORD_BUFFER_SIZE).await;
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
