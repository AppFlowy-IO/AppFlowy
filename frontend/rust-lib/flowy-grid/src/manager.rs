use crate::entities::GridLayout;

use crate::services::grid_editor::{GridRevisionCompress, GridRevisionEditor};
use crate::services::grid_view_manager::make_grid_view_rev_manager;
use crate::services::persistence::block_index::BlockIndexCache;
use crate::services::persistence::kv::GridKVPersistence;
use crate::services::persistence::migration::GridMigration;
use crate::services::persistence::rev_sqlite::SQLiteGridRevisionPersistence;
use crate::services::persistence::GridDatabase;
use bytes::Bytes;

use flowy_database::ConnectionPool;
use flowy_error::{FlowyError, FlowyResult};
use flowy_http_model::revision::Revision;
use flowy_revision::{
    RevisionManager, RevisionPersistence, RevisionPersistenceConfiguration, RevisionWebSocket,
    SQLiteRevisionSnapshotPersistence,
};
use flowy_sync::client_grid::{make_grid_block_operations, make_grid_operations, make_grid_view_operations};
use grid_rev_model::{BuildGridContext, GridRevision, GridViewRevision};
use lib_infra::ref_map::{RefCountHashMap, RefCountValue};

use crate::services::block_manager::make_grid_block_rev_manager;
use flowy_task::TaskDispatcher;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait GridUser: Send + Sync {
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct GridManager {
    grid_editors: RwLock<RefCountHashMap<Arc<GridRevisionEditor>>>,
    grid_user: Arc<dyn GridUser>,
    block_index_cache: Arc<BlockIndexCache>,
    #[allow(dead_code)]
    kv_persistence: Arc<GridKVPersistence>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    migration: GridMigration,
}

impl GridManager {
    pub fn new(
        grid_user: Arc<dyn GridUser>,
        _rev_web_socket: Arc<dyn RevisionWebSocket>,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
        database: Arc<dyn GridDatabase>,
    ) -> Self {
        let grid_editors = RwLock::new(RefCountHashMap::new());
        let kv_persistence = Arc::new(GridKVPersistence::new(database.clone()));
        let block_index_cache = Arc::new(BlockIndexCache::new(database.clone()));
        let migration = GridMigration::new(grid_user.clone(), database);
        Self {
            grid_editors,
            grid_user,
            kv_persistence,
            block_index_cache,
            task_scheduler,
            migration,
        }
    }

    pub async fn initialize_with_new_user(&self, _user_id: &str, _token: &str) -> FlowyResult<()> {
        Ok(())
    }

    pub async fn initialize(&self, _user_id: &str, _token: &str) -> FlowyResult<()> {
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub async fn create_grid<T: AsRef<str>>(&self, grid_id: T, revisions: Vec<Revision>) -> FlowyResult<()> {
        let grid_id = grid_id.as_ref();
        let db_pool = self.grid_user.db_pool()?;
        let rev_manager = self.make_grid_rev_manager(grid_id, db_pool)?;
        let _ = rev_manager.reset_object(revisions).await?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    async fn create_grid_view<T: AsRef<str>>(&self, view_id: T, revisions: Vec<Revision>) -> FlowyResult<()> {
        let view_id = view_id.as_ref();
        let rev_manager = make_grid_view_rev_manager(&self.grid_user, view_id).await?;
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub async fn create_grid_block<T: AsRef<str>>(&self, block_id: T, revisions: Vec<Revision>) -> FlowyResult<()> {
        let block_id = block_id.as_ref();
        let rev_manager = make_grid_block_rev_manager(&self.grid_user, block_id)?;
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip_all, err)]
    pub async fn open_grid<T: AsRef<str>>(&self, grid_id: T) -> FlowyResult<Arc<GridRevisionEditor>> {
        let grid_id = grid_id.as_ref();
        let _ = self.migration.run_v1_migration(grid_id).await;
        self.get_or_create_grid_editor(grid_id).await
    }

    #[tracing::instrument(level = "debug", skip_all, fields(grid_id), err)]
    pub async fn close_grid<T: AsRef<str>>(&self, grid_id: T) -> FlowyResult<()> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);

        self.grid_editors.write().await.remove(grid_id);
        // self.task_scheduler.write().await.unregister_handler(grid_id);
        Ok(())
    }

    // #[tracing::instrument(level = "debug", skip(self), err)]
    pub async fn get_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<GridRevisionEditor>> {
        match self.grid_editors.read().await.get(grid_id) {
            None => Err(FlowyError::internal().context("Should call open_grid function first")),
            Some(editor) => Ok(editor),
        }
    }

    async fn get_or_create_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<GridRevisionEditor>> {
        if let Some(editor) = self.grid_editors.read().await.get(grid_id) {
            return Ok(editor);
        }

        let db_pool = self.grid_user.db_pool()?;
        let editor = self.make_grid_rev_editor(grid_id, db_pool).await?;
        self.grid_editors
            .write()
            .await
            .insert(grid_id.to_string(), editor.clone());
        // self.task_scheduler.write().await.register_handler(editor.clone());
        Ok(editor)
    }

    #[tracing::instrument(level = "trace", skip(self, pool), err)]
    async fn make_grid_rev_editor(
        &self,
        grid_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<GridRevisionEditor>, FlowyError> {
        let user = self.grid_user.clone();
        let rev_manager = self.make_grid_rev_manager(grid_id, pool.clone())?;
        let grid_editor = GridRevisionEditor::new(
            grid_id,
            user,
            rev_manager,
            self.block_index_cache.clone(),
            self.task_scheduler.clone(),
        )
        .await?;
        Ok(grid_editor)
    }

    pub fn make_grid_rev_manager(
        &self,
        grid_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> FlowyResult<RevisionManager<Arc<ConnectionPool>>> {
        let user_id = self.grid_user.user_id()?;
        let disk_cache = SQLiteGridRevisionPersistence::new(&user_id, pool.clone());
        let configuration = RevisionPersistenceConfiguration::new(2, false);
        let rev_persistence = RevisionPersistence::new(&user_id, grid_id, disk_cache, configuration);
        let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(grid_id, pool);
        let rev_compactor = GridRevisionCompress();
        let rev_manager = RevisionManager::new(&user_id, grid_id, rev_persistence, rev_compactor, snapshot_persistence);
        Ok(rev_manager)
    }
}

pub async fn make_grid_view_data(
    _user_id: &str,
    view_id: &str,
    layout: GridLayout,
    grid_manager: Arc<GridManager>,
    build_context: BuildGridContext,
) -> FlowyResult<Bytes> {
    let BuildGridContext {
        field_revs,
        block_metas,
        blocks,
        grid_view_revision_data,
    } = build_context;

    for block_meta_data in &blocks {
        let block_id = &block_meta_data.block_id;
        // Indexing the block's rows
        block_meta_data.rows.iter().for_each(|row| {
            let _ = grid_manager.block_index_cache.insert(&row.block_id, &row.id);
        });

        // Create grid's block
        let grid_block_delta = make_grid_block_operations(block_meta_data);
        let block_delta_data = grid_block_delta.json_bytes();
        let revision = Revision::initial_revision(block_id, block_delta_data);
        let _ = grid_manager.create_grid_block(&block_id, vec![revision]).await?;
    }

    // Will replace the grid_id with the value returned by the gen_grid_id()
    let grid_id = view_id.to_owned();
    let grid_rev = GridRevision::from_build_context(&grid_id, field_revs, block_metas);

    // Create grid
    let grid_rev_delta = make_grid_operations(&grid_rev);
    let grid_rev_delta_bytes = grid_rev_delta.json_bytes();
    let revision = Revision::initial_revision(&grid_id, grid_rev_delta_bytes.clone());
    let _ = grid_manager.create_grid(&grid_id, vec![revision]).await?;

    // Create grid view
    let grid_view = if grid_view_revision_data.is_empty() {
        GridViewRevision::new(grid_id, view_id.to_owned(), layout.into())
    } else {
        GridViewRevision::from_json(grid_view_revision_data)?
    };
    let grid_view_delta = make_grid_view_operations(&grid_view);
    let grid_view_delta_bytes = grid_view_delta.json_bytes();
    let revision = Revision::initial_revision(view_id, grid_view_delta_bytes);
    let _ = grid_manager.create_grid_view(view_id, vec![revision]).await?;

    Ok(grid_rev_delta_bytes)
}

impl RefCountValue for GridRevisionEditor {
    fn did_remove(&self) {
        self.close();
    }
}
