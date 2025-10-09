use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab::entity::EncodedCollab;
use collab::lock::RwLock as CollabRwLock; // Renaming to avoid conflict with tokio::sync::RwLock
use collab::preclude::{Collab, Transact};
use collab_document::document::DocumentBody;
use collab_entity::{CollabObject, CollabType};
use flowy_ai_pub::entities::{UnindexedCollab, UnindexedCollabMetadata, UnindexedData};
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::async_trait::async_trait;
use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::sync::{Arc, Weak};
use std::time::Duration;
use tokio::runtime::Runtime;
use tokio::sync::RwLock; // Using tokio's RwLock for async-native locking
use tokio::time::{interval, Instant};
use tracing::{error, info, trace, warn};
use uuid::Uuid;

// --- Public Structures ---

pub struct WriteObject {
    pub collab_object: CollabObject,
    pub collab: Weak<dyn CollabIndexedData>,
}

pub struct InstantIndexedDataWriter {
    // Use tokio::sync::RwLock for async-native locking
    collab_by_object: Arc<RwLock<HashMap<String, WriteObject>>>,
    consumers: Arc<RwLock<Vec<Box<dyn InstantIndexedDataConsumer>>>>,
}

// --- Trait Definitions (kept as is, but used in advanced implementation) ---

#[async_trait]
pub trait CollabIndexedData: Send + Sync + 'static {
    // Added Option<FlowyError> to better handle internal data retrieval issues
    async fn get_unindexed_data(&self, collab_type: &CollabType) -> FlowyResult<Option<UnindexedData>>;
}

#[async_trait]
impl<T> CollabIndexedData for CollabRwLock<T>
where
    T: BorrowMut<Collab> + Send + Sync + 'static,
{
    // Simplified locking and using the CollabRwLock's async read functionality
    async fn get_unindexed_data(&self, collab_type: &CollabType) -> FlowyResult<Option<UnindexedData>> {
        let collab_guard = self.read().await;
        Ok(unindexed_data_form_collab(collab_guard.borrow(), collab_type))
    }
}

/// writer interface
#[async_trait]
pub trait InstantIndexedDataConsumer: Send + Sync + 'static {
    fn consumer_id(&self) -> String;

    async fn consume_collab(
        &self,
        workspace_id: &Uuid,
        data: Option<UnindexedData>,
        object_id: &Uuid,
        collab_type: CollabType,
    ) -> Result<bool, FlowyError>;

    async fn did_delete_collab(
        &self,
        workspace_id: &Uuid,
        object_id: &Uuid,
    ) -> Result<(), FlowyError>;
}

// --- Implementation ---

impl Default for InstantIndexedDataWriter {
    fn default() -> Self {
        Self::new()
    }
}

impl InstantIndexedDataWriter {
    pub fn new() -> InstantIndexedDataWriter {
        InstantIndexedDataWriter {
            collab_by_object: Arc::new(RwLock::new(HashMap::new())),
            consumers: Arc::new(RwLock::new(Vec::new())),
        }
    }
    
    // Public async methods... (omitted for brevity, they remain mostly the same)

    pub async fn num_consumers(&self) -> usize {
        self.consumers.read().await.len()
    }

    pub async fn clear_consumers(&self) {
        let mut consumers = self.consumers.write().await;
        consumers.clear();
        info!("[Indexing] Cleared all instant index consumers");
    }

    pub async fn register_consumer(&self, consumer: Box<dyn InstantIndexedDataConsumer>) {
        info!(
            "[Indexing] Registering instant index consumer: {}",
            consumer.consumer_id()
        );
        self.consumers.write().await.push(consumer);
    }
    
    // --- Core Logic Refactoring ---
    
    /// Spawns the periodic task that checks for live collabs and pushes data to consumers.
    pub async fn spawn_instant_indexed_provider(&self, runtime: &Runtime) -> FlowyResult<()> {
        let weak_collab_by_object = Arc::downgrade(&self.collab_by_object);
        let consumers_weak = Arc::downgrade(&self.consumers);
        let interval_dur = Duration::from_secs(30);

        runtime.spawn(async move {
            let mut ticker = interval(interval_dur);
            ticker.tick().await; // Skip the first tick

            loop {
                ticker.tick().await;

                let start_time = Instant::now();
                
                // 1. Upgrade Arcs or break if the writer has been dropped
                let collab_by_object = match weak_collab_by_object.upgrade() {
                    Some(m) => m,
                    None => break,
                };
                let consumers = match consumers_weak.upgrade() {
                    Some(c) => c,
                    None => break,
                };

                // 2. Snapshot keys and consumers
                let object_snapshots = {
                    let guard = collab_by_object.read().await;
                    // Clone the CollabObject and the Weak link's reference to the ID string,
                    // allowing us to release the read lock immediately.
                    guard.iter()
                        .map(|(id, wo)| (id.clone(), wo.collab_object.clone(), wo.collab.clone()))
                        .collect::<Vec<_>>()
                };

                let consumers_guard = consumers.read().await;
                if consumers_guard.is_empty() {
                    trace!("[Indexing] No consumers registered. Skipping tick.");
                    continue;
                }
                
                let mut to_remove = Vec::new();
                
                // 3. Process each object without holding the main map lock
                for (id, collab_object, weak_collab_data) in object_snapshots {
                    // Check if the collab is still alive
                    if let Some(collab_rc) = weak_collab_data.upgrade() {
                        let process_result = Self::process_single_collab(
                            id.clone(),
                            collab_object,
                            collab_rc,
                            &consumers_guard,
                        ).await;
                        
                        if let Err(e) = process_result {
                            error!("[Indexing] Failed to process collab {}: {}", id, e);
                        }
                    } else {
                        // Mark for removal if the collab object was dropped
                        to_remove.push(id);
                    }
                }

                // 4. Clean up stale entries
                if !to_remove.is_empty() {
                    let mut guard = collab_by_object.write().await;
                    let initial_count = guard.len();
                    guard.retain(|k, _| !to_remove.contains(k));
                    let removed_count = initial_count - guard.len();
                    trace!("[Indexing] Removed {} stale entries", removed_count);
                }
                
                let duration = start_time.elapsed();
                trace!("[Indexing] Provider tick finished in {:?}", duration);
            }

            info!("[Indexing] Instant indexed data provider stopped");
        });

        Ok(())
    }
    
    // New function to process a single collab, keeping the main loop clean.
    async fn process_single_collab(
        id: String,
        collab_object: CollabObject,
        collab_rc: Arc<dyn CollabIndexedData>,
        consumers: &[Box<dyn InstantIndexedDataConsumer>],
    ) -> FlowyResult<()> {
        let data = collab_rc
            .get_unindexed_data(&collab_object.collab_type)
            .await?; // Use ? to handle data retrieval errors

        let workspace_id = Uuid::parse_str(&collab_object.workspace_id)
            .map_err(|e| FlowyError::internal().with_context(format!("Invalid workspace_id: {}", e)))?;
        
        let object_id = Uuid::parse_str(&collab_object.object_id)
            .map_err(|e| FlowyError::internal().with_context(format!("Invalid object_id: {}", e)))?;

        for consumer in consumers.iter() {
            match consumer
                .consume_collab(
                    &workspace_id,
                    data.clone(),
                    &object_id,
                    collab_object.collab_type,
                )
                .await
            {
                Ok(is_indexed) => {
                    if is_indexed {
                        trace!("[Indexing] {} consumed {}", consumer.consumer_id(), id);
                    }
                }
                Err(err) => {
                    // Log consumer failure but continue to the next consumer/collab
                    warn!(
                        "Consumer {} failed on {}: {}",
                        consumer.consumer_id(),
                        id,
                        err
                    );
                }
            }
        }
        Ok(())
    }

    pub fn support_collab_type(&self, t: &CollabType) -> bool {
        matches!(t, CollabType::Document)
    }
    
    // index_encoded_collab and index_unindexed_collab remain largely the same,
    // as they correctly iterate over consumers and handle immediate indexing.

    pub async fn index_encoded_collab(
        &self,
        workspace_id: Uuid,
        object_id: Uuid,
        data: EncodedCollab,
        collab_type: CollabType,
    ) -> FlowyResult<()> {
        let unindexed = unindexed_collab_from_encoded_collab(workspace_id, object_id, data, collab_type)
            .ok_or_else(|| FlowyError::internal().with_context("Failed to create unindexed collab"))?;
        
        self.index_unindexed_collab(unindexed).await
    }

    pub async fn index_unindexed_collab(&self, data: UnindexedCollab) -> FlowyResult<()> {
        let consumers_guard = self.consumers.read().await;
        for consumer in consumers_guard.iter() {
            // Simplified error logging, but the logic is sound for immediate consumption
            if let Err(err) = consumer
                .consume_collab(
                    &data.workspace_id,
                    data.data.clone(),
                    &data.object_id,
                    data.collab_type,
                )
                .await
            {
                error!(
                    "Consumer {} failed on {}: {}",
                    consumer.consumer_id(),
                    data.object_id,
                    err
                );
            } else {
                trace!(
                    "[Indexing] {} consumed {}",
                    consumer.consumer_id(),
                    data.object_id
                );
            }
        }
        Ok(())
    }

    pub async fn queue_collab_embed(
        &self,
        collab_object: CollabObject,
        collab: Weak<dyn CollabIndexedData>,
    ) {
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

// --- Helper Functions (remain mostly the same) ---

pub fn unindexed_data_form_collab(
    collab: &Collab,
    collab_type: &CollabType,
) -> Option<UnindexedData> {
    match collab_type {
        CollabType::Document => {
            let txn = collab.doc().try_transact().ok()?;
            let doc = DocumentBody::from_collab(collab)?;
            let paras = doc.paragraphs(txn);
            Some(UnindexedData::Paragraphs(paras))
        }
        _ => None,
    }
}

pub fn unindexed_collab_from_encoded_collab(
    workspace_id: Uuid,
    object_id: Uuid,
    encoded_collab: EncodedCollab,
    collab_type: CollabType,
) -> Option<UnindexedCollab> {
    match collab_type {
        CollabType::Document => {
            let collab = Collab::new_with_source(
                CollabOrigin::Empty,
                &object_id.to_string(),
                DataSource::DocStateV1(encoded_collab.doc_state.to_vec()),
                vec![],
                false,
            )
            .ok()?;
            let data = unindexed_data_form_collab(&collab, &collab_type)?;
            Some(UnindexedCollab {
                workspace_id,
                object_id,
                collab_type,
                data: Some(data),
                metadata: UnindexedCollabMetadata::default(),
            })
        }
        _ => None,
    }
}

// --- End of Code ---
