use crate::services::grid_editor::ClientGridEditor;
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::{RevisionManager, RevisionPersistence, RevisionWebSocket};
use lib_sqlite::ConnectionPool;
use std::sync::Arc;

pub trait GridUser: Send + Sync {
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct GridManager {
    grid_editors: Arc<GridEditors>,
    grid_user: Arc<dyn GridUser>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
}

impl GridManager {
    pub fn new(grid_user: Arc<dyn GridUser>, rev_web_socket: Arc<dyn RevisionWebSocket>) -> Self {
        let grid_editors = Arc::new(GridEditors::new());
        Self {
            grid_editors,
            grid_user,
            rev_web_socket,
        }
    }

    #[tracing::instrument(level = "debug", skip(self, grid_id), fields(grid_id), err)]
    pub async fn open_grid<T: AsRef<str>>(&self, grid_id: T) -> Result<Arc<ClientGridEditor>, FlowyError> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.get_grid_editor(grid_id).await
    }

    #[tracing::instrument(level = "trace", skip(self, grid_id), fields(grid_id), err)]
    pub fn close_grid<T: AsRef<str>>(&self, grid_id: T) -> Result<(), FlowyError> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.grid_editors.remove(grid_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, grid_id), fields(doc_id), err)]
    pub fn delete_grid<T: AsRef<str>>(&self, grid_id: T) -> Result<(), FlowyError> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.grid_editors.remove(grid_id);
        Ok(())
    }

    async fn get_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<ClientGridEditor>> {
        match self.grid_editors.get(grid_id) {
            None => {
                let db_pool = self.grid_user.db_pool()?;
                self.make_grid_editor(grid_id, db_pool).await
            }
            Some(editor) => Ok(editor),
        }
    }

    async fn make_grid_editor(
        &self,
        grid_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientGridEditor>, FlowyError> {
        let token = self.grid_user.token()?;
        let user_id = self.grid_user.user_id()?;
        let grid_editor = ClientGridEditor::new(&user_id, grid_id, &token, pool, self.rev_web_socket.clone()).await?;
        self.grid_editors.insert(grid_id, &grid_editor);
        Ok(grid_editor)
    }
}

pub struct GridEditors {
    inner: DashMap<String, Arc<ClientGridEditor>>,
}

impl GridEditors {
    fn new() -> Self {
        Self { inner: DashMap::new() }
    }

    pub(crate) fn insert(&self, grid_id: &str, grid_editor: &Arc<ClientGridEditor>) {
        if self.inner.contains_key(grid_id) {
            tracing::warn!("Grid:{} already exists in cache", grid_id);
        }
        self.inner.insert(grid_id.to_string(), grid_editor.clone());
    }

    pub(crate) fn contains(&self, grid_id: &str) -> bool {
        self.inner.get(grid_id).is_some()
    }

    pub(crate) fn get(&self, grid_id: &str) -> Option<Arc<ClientGridEditor>> {
        if !self.contains(grid_id) {
            return None;
        }
        let opened_grid = self.inner.get(grid_id).unwrap();
        Some(opened_grid.clone())
    }

    pub(crate) fn remove(&self, grid_id: &str) {
        self.inner.remove(grid_id);
    }
}
