use collab::lock::RwLock;
use collab::preclude::{Collab, Transact};
use collab_document::document::DocumentBody;
use collab_entity::{CollabObject, CollabType};
use flowy_ai_pub::entities::UnindexedData;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::sync::{Arc, Weak};
use std::time::Duration;
use tracing::{error, trace};

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
  pub collab: Weak<dyn CollabBorrower + Send + Sync + 'static>,
}

// Define a trait that all collab types can implement
pub trait CollabBorrower {
  fn borrow_collab(&self) -> &Collab;
}

// Implement for any type that implements BorrowMut<Collab>
impl<T: BorrowMut<Collab> + 'static> CollabBorrower for RwLock<T> {
  fn borrow_collab(&self) -> &Collab {
    // This requires interior mutability which RwLock provides
    unsafe {
      // Safety: We're just borrowing the Collab for a reference
      // The actual mutation happens through proper channels
      let collab_ptr = self as *const RwLock<T>;
      let collab_ref = &*collab_ptr;
      let guard = collab_ref.blocking_read();
      let collab_ref = guard.borrow() as *const Collab;
      &*collab_ref
    }
  }
}

// Implement CollabBorrower for Arc<dyn CollabBorrower>
impl CollabBorrower for Arc<dyn CollabBorrower + Send + Sync> {
  fn borrow_collab(&self) -> &Collab {
    (**self).borrow_collab()
  }
}

pub struct PeriodicallyEmbeddingWrite {
  #[allow(dead_code)]
  // Just use to bind the lifetime of the spawned task
  collab_by_object: Arc<RwLock<HashMap<String, WriteObject>>>,
}

impl PeriodicallyEmbeddingWrite {
  pub fn new(writer: impl PeriodicallyWriter) -> PeriodicallyEmbeddingWrite {
    let duration = Duration::from_secs(30);
    let collab_by_object = Arc::new(RwLock::new(HashMap::<String, WriteObject>::new()));
    let weak_collab_by_object = Arc::downgrade(&collab_by_object);

    tokio::spawn(async move {
      loop {
        tokio::time::sleep(duration).await;
        match weak_collab_by_object.upgrade() {
          Some(collab_by_object) => {
            let mut objects_to_remove = Vec::new();

            // First pass: process objects and identify ones to remove
            {
              let guard = collab_by_object.read().await;
              trace!("[Embedding] Processing {} collab objects", guard.len());

              for (object_id, write_object) in guard.iter() {
                if let Some(collab) = write_object.collab.upgrade() {
                  let data = index_data_for_collab_borrower(
                    &collab,
                    &write_object.collab_object.collab_type,
                  );
                  if let Some(data) = data {
                    if let Err(e) = writer.write(&write_object.collab_object, data).await {
                      error!("Failed to write collab object {}: {}", object_id, e);
                    }
                  }
                } else {
                  // Weak reference can't be upgraded, mark for removal
                  objects_to_remove.push(object_id.clone());
                }
              }
            }

            // Second pass: remove objects that can't be upgraded
            if !objects_to_remove.is_empty() {
              let mut guard = collab_by_object.write().await;
              for object_id in objects_to_remove {
                guard.remove(&object_id);
              }
            }
          },
          None => break,
        }
      }
    });

    Self { collab_by_object }
  }

  pub fn support_collab_type(&self, collab_type: &CollabType) -> bool {
    match collab_type {
      CollabType::Document => true,
      _ => false,
    }
  }

  pub fn add_collab<T>(&self, collab_object: CollabObject, collab: Weak<RwLock<T>>)
  where
    T: BorrowMut<Collab> + Send + Sync + 'static,
  {
    // Cast from Weak<RwLock<T>> to Weak<dyn CollabBorrower>
    let collab: Weak<dyn CollabBorrower + Send + Sync> = collab;

    let object_id = collab_object.object_id.clone();
    let mut guard = self.collab_by_object.blocking_write();
    guard.insert(
      object_id,
      WriteObject {
        collab_object,
        collab,
      },
    );
  }
}

fn index_data_for_collab_borrower(
  collab: &(dyn CollabBorrower + Send + Sync),
  collab_type: &CollabType,
) -> Option<UnindexedData> {
  let collab = collab.borrow_collab();
  index_data_for_collab(collab, collab_type)
}

fn index_data_for_collab(collab: &Collab, collab_type: &CollabType) -> Option<UnindexedData> {
  match collab_type {
    CollabType::Document => {
      let txn = collab.doc().try_transact().ok()?;
      let document = DocumentBody::from_collab(collab)?;
      let paragraphs = document.paragraphs(txn);
      Some(UnindexedData::Paragraphs(paragraphs))
    },
    _ => None,
  }
}
