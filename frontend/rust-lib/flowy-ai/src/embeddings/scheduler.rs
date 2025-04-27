use crate::embeddings::embedder::{Embedder, OllamaEmbedder};
use crate::embeddings::faiss::FaissController;
use crate::embeddings::indexer::{EmbeddedChunk, EmbeddingModel, IndexerProvider};
use arc_swap::ArcSwapOption;
use flowy_ai_pub::cloud::CollabType;
use flowy_ai_pub::persistence::{
  select_collabs_fragment_ids, upsert_collab_embeddings, FaissFragment, Fragment,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use ollama_rs::Ollama;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tokio::sync::{mpsc, RwLock};
use tracing::{debug, error, info, trace, warn};
use uuid::Uuid;

pub trait EmbeddingSchedulerDB: Send + Sync {
  fn db_connection(&self) -> FlowyResult<DBConnection>;
  fn embedding_db_dir(&self) -> FlowyResult<PathBuf>;
}

pub struct EmbeddingScheduler {
  db: Arc<dyn EmbeddingSchedulerDB>,
  indexer_provider: Arc<IndexerProvider>,
  write_embedding_tx: UnboundedSender<EmbeddingRecord>,
  generate_embedding_tx: mpsc::Sender<UnindexedCollab>,
  ollama: ArcSwapOption<Ollama>,
  faiss: Arc<RwLock<FaissController>>,
}

impl EmbeddingScheduler {
  pub fn new(
    workspace_id: &Uuid,
    db: Arc<dyn EmbeddingSchedulerDB>,
    ollama: ArcSwapOption<Ollama>,
  ) -> FlowyResult<Arc<EmbeddingScheduler>> {
    let indexer_provider = IndexerProvider::new();
    let (write_embedding_tx, write_embedding_rx) = unbounded_channel::<EmbeddingRecord>();
    let (generate_embedding_tx, gen_embedding_rx) = mpsc::channel::<UnindexedCollab>(100);
    let faiss = Arc::new(RwLock::new(FaissController::new(
      db.embedding_db_dir().unwrap(),
      workspace_id.to_string(),
      EmbeddingModel::NomicEmbedText,
    )?));

    let this = Arc::new(Self {
      db,
      indexer_provider,
      write_embedding_tx,
      generate_embedding_tx,
      ollama,
      faiss,
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
    let ollama = self
      .ollama
      .load_full()
      .ok_or_else(|| FlowyError::local_ai().with_context("Failed to load ollama"))?;
    let embedder = Embedder::Ollama(OllamaEmbedder {
      ollama: ollama.clone(),
    });
    Ok(embedder)
  }

  pub fn index_collab(&self, data: UnindexedCollab) -> FlowyResult<()> {
    // Perform indexing logic here
    Ok(())
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
    let mut conn = match scheduler.db.db_connection() {
      Ok(conn) => conn,
      Err(_) => {
        return;
      },
    };

    let records = buf.drain(..n).collect::<Vec<_>>();
    for record in records.into_iter() {
      debug!(
        "[Embedding] pg write collab:{} embeddings",
        record.object_id,
      );

      let mut chunks = vec![];
      let mut faiss_write = scheduler.faiss.write().await;
      for chunk in record.chunks {
        if let Some(embeddings) = chunk.embedding {
          if let Ok(faiss_id) = faiss_write.add(&embeddings) {
            chunks.push(FaissFragment {
              faiss_id,
              data: Fragment {
                fragment_id: chunk.fragment_id,
                content_type: 0,
                contents: chunk.content,
                metadata: chunk.metadata,
                fragment_index: chunk.fragment_index,
                embedded_type: chunk.embedded_type,
              },
            });
          }
        }
      }
      drop(faiss_write);

      match upsert_collab_embeddings(&mut conn, &record.object_id.to_string(), chunks) {
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

    let mut conn = match scheduler.db.db_connection() {
      Ok(conn) => conn,
      Err(err) => {
        error!("[Embedding] Failed to get db connection: {}", err);
        return;
      },
    };

    match embedder {
      Ok(embedder) => {
        let params: Vec<_> = records.iter().map(|r| r.object_id.to_string()).collect();
        let existing_embeddings =
          select_collabs_fragment_ids(&mut conn, &params).unwrap_or_else(|err| {
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

pub struct EmbeddingRecord {
  pub workspace_id: Uuid,
  pub object_id: Uuid,
  pub chunks: Vec<EmbeddedChunk>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnindexedCollab {
  pub workspace_id: Uuid,
  pub object_id: Uuid,
  pub collab_type: CollabType,
  pub data: UnindexedData,
  pub created_at: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum UnindexedData {
  Text(String),
  Paragraphs(Vec<String>),
}
