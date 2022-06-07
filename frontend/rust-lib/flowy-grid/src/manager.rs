use crate::services::block::make_grid_block_meta_rev_manager;
use crate::services::grid_meta_editor::GridMetaEditor;
use crate::services::persistence::block_index::BlockIndexCache;
use crate::services::persistence::kv::GridKVPersistence;
use crate::services::persistence::GridDatabase;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{BuildGridContext, GridMeta};
use flowy_revision::disk::SQLiteGridRevisionPersistence;
use flowy_revision::{RevisionManager, RevisionPersistence, RevisionWebSocket};
use flowy_sync::client_grid::{make_block_meta_delta, make_grid_delta};
use flowy_sync::entities::revision::{RepeatedRevision, Revision};
use std::sync::Arc;

pub trait GridUser: Send + Sync {
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct GridManager {
    editor_map: Arc<DashMap<String, Arc<GridMetaEditor>>>,
    grid_user: Arc<dyn GridUser>,
    block_index_cache: Arc<BlockIndexCache>,
    #[allow(dead_code)]
    kv_persistence: Arc<GridKVPersistence>,
}

impl GridManager {
    pub fn new(
        grid_user: Arc<dyn GridUser>,
        _rev_web_socket: Arc<dyn RevisionWebSocket>,
        database: Arc<dyn GridDatabase>,
    ) -> Self {
        let grid_editors = Arc::new(DashMap::new());
        let kv_persistence = Arc::new(GridKVPersistence::new(database.clone()));
        let block_index_cache = Arc::new(BlockIndexCache::new(database));
        Self {
            editor_map: grid_editors,
            grid_user,
            block_index_cache,
            kv_persistence,
        }
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub async fn create_grid<T: AsRef<str>>(&self, grid_id: T, revisions: RepeatedRevision) -> FlowyResult<()> {
        let grid_id = grid_id.as_ref();
        let db_pool = self.grid_user.db_pool()?;
        let rev_manager = self.make_grid_rev_manager(grid_id, db_pool)?;
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub async fn create_grid_block_meta<T: AsRef<str>>(
        &self,
        block_id: T,
        revisions: RepeatedRevision,
    ) -> FlowyResult<()> {
        let rev_manager = make_grid_block_meta_rev_manager(&self.grid_user, block_id.as_ref())?;
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip_all, fields(grid_id), err)]
    pub async fn open_grid<T: AsRef<str>>(&self, grid_id: T) -> FlowyResult<Arc<GridMetaEditor>> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.get_or_create_grid_editor(grid_id).await
    }

    #[tracing::instrument(level = "debug", skip_all, fields(grid_id), err)]
    pub fn close_grid<T: AsRef<str>>(&self, grid_id: T) -> FlowyResult<()> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.editor_map.remove(grid_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, grid_id), fields(doc_id), err)]
    pub fn delete_grid<T: AsRef<str>>(&self, grid_id: T) -> FlowyResult<()> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.editor_map.remove(grid_id);
        Ok(())
    }

    // #[tracing::instrument(level = "debug", skip(self), err)]
    pub fn get_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<GridMetaEditor>> {
        match self.editor_map.get(grid_id) {
            None => Err(FlowyError::internal().context("Should call open_grid function first")),
            Some(editor) => Ok(editor.clone()),
        }
    }

    async fn get_or_create_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<GridMetaEditor>> {
        match self.editor_map.get(grid_id) {
            None => {
                tracing::trace!("Create grid editor with id: {}", grid_id);
                let db_pool = self.grid_user.db_pool()?;
                let editor = self.make_grid_editor(grid_id, db_pool).await?;

                if self.editor_map.contains_key(grid_id) {
                    tracing::warn!("Grid:{} already exists in cache", grid_id);
                }
                self.editor_map.insert(grid_id.to_string(), editor.clone());
                Ok(editor)
            }
            Some(editor) => Ok(editor.clone()),
        }
    }

    #[tracing::instrument(level = "trace", skip(self, pool), err)]
    async fn make_grid_editor(
        &self,
        grid_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<GridMetaEditor>, FlowyError> {
        let user = self.grid_user.clone();
        let rev_manager = self.make_grid_rev_manager(grid_id, pool.clone())?;
        let grid_editor = GridMetaEditor::new(grid_id, user, rev_manager, self.block_index_cache.clone()).await?;
        Ok(grid_editor)
    }

    pub fn make_grid_rev_manager(&self, grid_id: &str, pool: Arc<ConnectionPool>) -> FlowyResult<RevisionManager> {
        let user_id = self.grid_user.user_id()?;

        let disk_cache = Arc::new(SQLiteGridRevisionPersistence::new(&user_id, pool));
        let rev_persistence = Arc::new(RevisionPersistence::new(&user_id, grid_id, disk_cache));
        let rev_manager = RevisionManager::new(&user_id, grid_id, rev_persistence);
        Ok(rev_manager)
    }
}

pub async fn make_grid_view_data(
    user_id: &str,
    view_id: &str,
    grid_manager: Arc<GridManager>,
    build_context: BuildGridContext,
) -> FlowyResult<Bytes> {
    let grid_meta = GridMeta {
        grid_id: view_id.to_string(),
        fields: build_context.field_metas,
        blocks: build_context.blocks,
    };

    // Create grid
    let grid_meta_delta = make_grid_delta(&grid_meta);
    let grid_delta_data = grid_meta_delta.to_delta_bytes();
    let repeated_revision: RepeatedRevision =
        Revision::initial_revision(user_id, view_id, grid_delta_data.clone()).into();
    let _ = grid_manager.create_grid(view_id, repeated_revision).await?;
    for block_meta_data in build_context.blocks_meta_data {
        let block_id = block_meta_data.block_id.clone();

        // Indexing the block's rows
        block_meta_data.rows.iter().for_each(|row| {
            let _ = grid_manager.block_index_cache.insert(&row.block_id, &row.id);
        });

        // Create grid's block
        let grid_block_meta_delta = make_block_meta_delta(&block_meta_data);
        let block_meta_delta_data = grid_block_meta_delta.to_delta_bytes();
        let repeated_revision: RepeatedRevision =
            Revision::initial_revision(user_id, &block_id, block_meta_delta_data).into();
        let _ = grid_manager
            .create_grid_block_meta(&block_id, repeated_revision)
            .await?;
    }

    Ok(grid_delta_data)
}
