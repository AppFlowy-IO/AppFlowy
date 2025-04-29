use collab::lock::RwLock;
use collab::preclude::{Collab, Transact};
use collab_document::document::DocumentBody;
use collab_entity::{CollabObject, CollabType};
use flowy_ai_pub::entities::UnindexedData;
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;
use lib_infra::util::get_operating_system;
use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::sync::{Arc, Weak};
use std::time::Duration;
use tokio::runtime::Runtime;
use tokio::time::interval;
use tracing::{error, trace};
use uuid::Uuid;

#[async_trait]
pub trait CollabIndexedData: Send + Sync + 'static {
  /// upgrade and get a &Collab
  async fn get_unindexed_data(&self, collab_type: &CollabType) -> Option<UnindexedData>;
}

/// blanket-impl for any `RwLock<T>` where `T: BorrowMut<Collab>`
#[async_trait]
impl<T> CollabIndexedData for RwLock<T>
where
  T: BorrowMut<Collab> + Send + Sync + 'static,
{
  async fn get_unindexed_data(&self, collab_type: &CollabType) -> Option<UnindexedData> {
    let collab = self.try_read().ok()?;
    index_data_for_collab(collab.borrow(), collab_type)
  }
}

/// writer interface
#[async_trait]
pub trait InstantIndexedDataConsumer: Send + Sync + 'static {
  fn indexed_consumer_id(&self) -> String;

  async fn consume_collab(
    &self,
    collab_object: &CollabObject,
    data: UnindexedData,
  ) -> Result<(), FlowyError>;

  async fn did_delete_collab(
    &self,
    workspace_id: &Uuid,
    object_id: &Uuid,
  ) -> Result<(), FlowyError>;
}

pub struct WriteObject {
  pub collab_object: CollabObject,
  pub collab: Weak<dyn CollabIndexedData>,
}

pub struct InstantIndexedDataProvider {
  collab_by_object: Arc<RwLock<HashMap<String, WriteObject>>>,
  consumers: Arc<RwLock<Vec<Box<dyn InstantIndexedDataConsumer>>>>,
}

impl Default for InstantIndexedDataProvider {
  fn default() -> Self {
    Self::new()
  }
}

impl InstantIndexedDataProvider {
  pub fn new() -> InstantIndexedDataProvider {
    let collab_by_object = Arc::new(RwLock::new(HashMap::<String, WriteObject>::new()));
    let consumers = Arc::new(RwLock::new(
      Vec::<Box<dyn InstantIndexedDataConsumer>>::new(),
    ));

    InstantIndexedDataProvider {
      collab_by_object,
      consumers,
    }
  }

  pub async fn num_consumers(&self) -> usize {
    let consumers = self.consumers.read().await;
    consumers.len()
  }

  pub async fn register_consumer(&self, consumer: Box<dyn InstantIndexedDataConsumer>) {
    let mut guard = self.consumers.write().await;
    guard.push(consumer);
  }

  pub async fn spawn_instant_indexed_provider(&self, runtime: &Runtime) -> FlowyResult<()> {
    if !get_operating_system().is_desktop() {
      return Ok(());
    }

    let weak_collab_by_object = Arc::downgrade(&self.collab_by_object);
    let consumers_weak = Arc::downgrade(&self.consumers);
    let interval_dur = Duration::from_secs(30);

    runtime.spawn(async move {
      let mut ticker = interval(interval_dur);
      ticker.tick().await;

      loop {
        ticker.tick().await;

        // Upgrade our state holders
        let collab_by_object = match weak_collab_by_object.upgrade() {
          Some(m) => m,
          None => break, // provider dropped
        };
        let consumers_arc = match consumers_weak.upgrade() {
          Some(c) => c,
          None => break,
        };

        // Snapshot keys and consumers under read locks
        let (object_ids, mut to_remove) = {
          let guard = collab_by_object.read().await;
          trace!("[Indexing] Found {} objects to check", guard.len());
          let keys: Vec<_> = guard.keys().cloned().collect();
          (keys, Vec::new())
        };
        let guard = collab_by_object.read().await;
        for id in object_ids {
          // Check if the collab is still alive
          match guard.get(&id) {
            Some(wo) => {
              if let Some(collab_rc) = wo.collab.upgrade() {
                if let Some(data) = collab_rc
                  .get_unindexed_data(&wo.collab_object.collab_type)
                  .await
                {
                  // Snapshot consumers
                  let consumers_snapshot = consumers_arc.read().await;
                  for consumer in consumers_snapshot.iter() {
                    trace!(
                      "[Indexing] {} consuming {}",
                      consumer.indexed_consumer_id(),
                      id
                    );
                    if let Err(e) = consumer
                      .consume_collab(&wo.collab_object, data.clone())
                      .await
                    {
                      error!(
                        "Consumer {} failed on {}: {}",
                        consumer.indexed_consumer_id(),
                        id,
                        e
                      );
                    }
                  }
                }
              } else {
                // Mark for removal if collab was dropped
                to_remove.push(id);
              }
            },
            None => continue,
          }
        }

        if !to_remove.is_empty() {
          let mut guard = collab_by_object.write().await;
          guard.retain(|k, _| !to_remove.contains(k));
          trace!("[Indexing] Removed {} stale entries", to_remove.len());
        }
      }
    });

    Ok(())
  }

  pub fn support_collab_type(&self, t: &CollabType) -> bool {
    matches!(t, CollabType::Document)
  }

  pub async fn queue_collab_embed(
    &self,
    collab_object: CollabObject,
    collab: Weak<dyn CollabIndexedData>,
  ) {
    if !get_operating_system().is_desktop() {
      return;
    }

    if !self.support_collab_type(&collab_object.collab_type) {
      return;
    }

    let mut map = self.collab_by_object.write().await;
    map.insert(
      collab_object.object_id.clone(),
      WriteObject {
        collab_object,
        collab,
      },
    );
  }
}

fn index_data_for_collab(collab: &Collab, collab_type: &CollabType) -> Option<UnindexedData> {
  match collab_type {
    CollabType::Document => {
      let txn = collab.doc().try_transact().ok()?;
      let doc = DocumentBody::from_collab(collab)?;
      let paras = doc.paragraphs(txn);
      if paras.is_empty() {
        trace!("[Indexing] No paragraphs in {}", collab.object_id());
        return None;
      }
      Some(UnindexedData::Paragraphs(paras))
    },
    _ => None,
  }
}
