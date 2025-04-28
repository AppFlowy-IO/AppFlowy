use collab::lock::RwLock;
use collab::preclude::{Collab, Transact};
use collab_document::document::DocumentBody;
use collab_entity::{CollabObject, CollabType};
use flowy_ai_pub::entities::UnindexedData;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use lib_infra::util::get_operating_system;
use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::sync::{Arc, Weak};
use std::time::Duration;
use tokio::runtime::Runtime;
use tracing::{error, trace};
#[async_trait]
pub trait CollabBorrower: Send + Sync + 'static {
  /// upgrade and get a &Collab
  async fn get_unindexed_data(&self, collab_type: &CollabType) -> Option<UnindexedData>;
}

/// blanket-impl for any `RwLock<T>` where `T: BorrowMut<Collab>`
#[async_trait]
impl<T> CollabBorrower for RwLock<T>
where
  T: BorrowMut<Collab> + Send + Sync + 'static,
{
  async fn get_unindexed_data(&self, collab_type: &CollabType) -> Option<UnindexedData> {
    let guard = self.read().await;
    index_data_for_collab(guard.borrow(), collab_type)
  }
}

/// writer interface
#[async_trait]
pub trait PeriodicallyWriter: Send + Sync + 'static {
  async fn write(
    &self,
    collab_object: &CollabObject,
    data: UnindexedData,
  ) -> Result<(), FlowyError>;
}

pub struct WriteObject {
  pub collab_object: CollabObject,
  /// trait‐object reference to any RwLock<T> that can yield a Collab
  pub collab: Weak<dyn CollabBorrower>,
}

pub struct PeriodicallyEmbeddingWrite {
  collab_by_object: Arc<RwLock<HashMap<String, WriteObject>>>,
}

impl PeriodicallyEmbeddingWrite {
  pub fn new(writer: impl PeriodicallyWriter, runtime: &Runtime) -> PeriodicallyEmbeddingWrite {
    let duration = Duration::from_secs(20);
    let collab_by_object = Arc::new(RwLock::new(HashMap::<String, WriteObject>::new()));
    let weak_map = Arc::downgrade(&collab_by_object);

    if get_operating_system().is_desktop() {
      runtime.spawn(async move {
        // initial delay
        tokio::time::sleep(duration).await;
        loop {
          tokio::time::sleep(duration).await;
          if let Some(map_arc) = weak_map.upgrade() {
            let mut to_remove = Vec::new();
            {
              let guard = map_arc.read().await;
              trace!("[Embedding] Processing {} objects", guard.len());
              for (id, wo) in guard.iter() {
                if let Some(carc) = wo.collab.upgrade() {
                  // use the trait to borrow Collab
                  let data = carc.get_unindexed_data(&wo.collab_object.collab_type).await;
                  if let Some(data) = data {
                    if let Err(e) = writer.write(&wo.collab_object, data).await {
                      error!("Failed to write {}: {}", id, e);
                    }
                  }
                } else {
                  to_remove.push(id.clone());
                }
              }
            }
            if !to_remove.is_empty() {
              let mut guard = map_arc.write().await;
              for id in to_remove {
                guard.remove(&id);
              }
            }
          } else {
            break;
          }
        }
      });
    }

    PeriodicallyEmbeddingWrite { collab_by_object }
  }

  pub fn support_collab_type(&self, t: &CollabType) -> bool {
    matches!(t, CollabType::Document)
  }

  /// --- 3) now takes a trait‐object Weak
  pub async fn add_collab(&self, collab_object: CollabObject, collab: Weak<dyn CollabBorrower>) {
    if !get_operating_system().is_desktop() {
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
        trace!("[Embedding] No paragraphs in {}", collab.object_id());
        return None;
      }
      Some(UnindexedData::Paragraphs(paras))
    },
    _ => None,
  }
}
