use crate::services::grid_editor::ClientGridEditor;
use crate::services::kv_persistence::GridKVPersistence;
use dashmap::DashMap;
use flowy_collaboration::entities::revision::RepeatedRevision;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::disk::{SQLiteGridBlockMetaRevisionPersistence, SQLiteGridRevisionPersistence};
use flowy_sync::{RevisionManager, RevisionPersistence, RevisionWebSocket};
use lib_sqlite::ConnectionPool;
use parking_lot::RwLock;
use std::sync::Arc;

pub trait GridUser: Send + Sync {
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct GridManager {
    editor_map: Arc<GridEditorMap>,
    grid_user: Arc<dyn GridUser>,
    kv_persistence: Arc<RwLock<Option<Arc<GridKVPersistence>>>>,
}

impl GridManager {
    pub fn new(grid_user: Arc<dyn GridUser>, _rev_web_socket: Arc<dyn RevisionWebSocket>) -> Self {
        let grid_editors = Arc::new(GridEditorMap::new());

        // kv_persistence will be initialized after first access.
        // See get_kv_persistence function below
        let kv_persistence = Arc::new(RwLock::new(None));
        Self {
            editor_map: grid_editors,
            grid_user,
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
        let block_id = block_id.as_ref();
        let db_pool = self.grid_user.db_pool()?;
        let rev_manager = self.make_grid_block_meta_rev_manager(block_id, db_pool)?;
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip_all, fields(grid_id), err)]
    pub async fn open_grid<T: AsRef<str>>(&self, grid_id: T) -> FlowyResult<Arc<ClientGridEditor>> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.get_or_create_grid_editor(grid_id).await
    }

    #[tracing::instrument(level = "trace", skip_all, fields(grid_id), err)]
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

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub fn get_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<ClientGridEditor>> {
        match self.editor_map.get(grid_id) {
            None => Err(FlowyError::internal().context("Should call open_grid function first")),
            Some(editor) => Ok(editor),
        }
    }

    async fn get_or_create_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<ClientGridEditor>> {
        match self.editor_map.get(grid_id) {
            None => {
                tracing::trace!("Create grid editor with id: {}", grid_id);
                let db_pool = self.grid_user.db_pool()?;
                let editor = self.make_grid_editor(grid_id, db_pool).await?;
                self.editor_map.insert(grid_id, &editor);
                Ok(editor)
            }
            Some(editor) => Ok(editor),
        }
    }

    async fn make_grid_editor(
        &self,
        grid_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientGridEditor>, FlowyError> {
        let user = self.grid_user.clone();
        let rev_manager = self.make_grid_rev_manager(grid_id, pool.clone())?;
        let kv_persistence = self.get_kv_persistence()?;
        let grid_editor = ClientGridEditor::new(grid_id, user, rev_manager, kv_persistence).await?;
        Ok(grid_editor)
    }

    pub fn make_grid_rev_manager(&self, grid_id: &str, pool: Arc<ConnectionPool>) -> FlowyResult<RevisionManager> {
        let user_id = self.grid_user.user_id()?;

        let disk_cache = Arc::new(SQLiteGridRevisionPersistence::new(&user_id, pool));
        let rev_persistence = Arc::new(RevisionPersistence::new(&user_id, grid_id, disk_cache));
        let rev_manager = RevisionManager::new(&user_id, grid_id, rev_persistence);
        Ok(rev_manager)
    }

    fn make_grid_block_meta_rev_manager(
        &self,
        block_d: &str,
        pool: Arc<ConnectionPool>,
    ) -> FlowyResult<RevisionManager> {
        let user_id = self.grid_user.user_id()?;
        let disk_cache = Arc::new(SQLiteGridBlockMetaRevisionPersistence::new(&user_id, pool));
        let rev_persistence = Arc::new(RevisionPersistence::new(&user_id, block_d, disk_cache));
        let rev_manager = RevisionManager::new(&user_id, block_d, rev_persistence);
        Ok(rev_manager)
    }

    fn get_kv_persistence(&self) -> FlowyResult<Arc<GridKVPersistence>> {
        let read_guard = self.kv_persistence.read();
        if read_guard.is_some() {
            return Ok(read_guard.clone().unwrap());
        }
        drop(read_guard);

        let pool = self.grid_user.db_pool()?;
        let kv_persistence = Arc::new(GridKVPersistence::new(pool));
        *self.kv_persistence.write() = Some(kv_persistence.clone());
        Ok(kv_persistence)
    }
}

pub struct GridEditorMap {
    inner: DashMap<String, Arc<ClientGridEditor>>,
}

impl GridEditorMap {
    fn new() -> Self {
        Self { inner: DashMap::new() }
    }

    pub(crate) fn insert(&self, grid_id: &str, grid_editor: &Arc<ClientGridEditor>) {
        if self.inner.contains_key(grid_id) {
            tracing::warn!("Grid:{} already exists in cache", grid_id);
        }
        self.inner.insert(grid_id.to_string(), grid_editor.clone());
    }

    pub(crate) fn get(&self, grid_id: &str) -> Option<Arc<ClientGridEditor>> {
        Some(self.inner.get(grid_id)?.clone())
    }

    pub(crate) fn remove(&self, grid_id: &str) {
        self.inner.remove(grid_id);
    }
}
