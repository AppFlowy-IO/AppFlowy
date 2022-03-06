use crate::services::grid_editor::ClientGridEditor;
use crate::services::kv_persistence::GridKVPersistence;
use dashmap::DashMap;
use flowy_collaboration::client_grid::make_grid_delta;
use flowy_collaboration::entities::revision::RepeatedRevision;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{Field, FieldOrder, FieldType, Grid, RawRow, RowOrder};
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
    grid_editors: Arc<GridEditors>,
    grid_user: Arc<dyn GridUser>,
    kv_persistence: Arc<RwLock<Option<Arc<GridKVPersistence>>>>,
}

impl GridManager {
    pub fn new(grid_user: Arc<dyn GridUser>, _rev_web_socket: Arc<dyn RevisionWebSocket>) -> Self {
        let grid_editors = Arc::new(GridEditors::new());

        // kv_persistence will be initialized after first access.
        // See get_kv_persistence function below
        let kv_persistence = Arc::new(RwLock::new(None));
        Self {
            grid_editors,
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
        self.grid_editors.remove(grid_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, grid_id), fields(doc_id), err)]
    pub fn delete_grid<T: AsRef<str>>(&self, grid_id: T) -> FlowyResult<()> {
        let grid_id = grid_id.as_ref();
        tracing::Span::current().record("grid_id", &grid_id);
        self.grid_editors.remove(grid_id);
        Ok(())
    }

    pub fn get_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<ClientGridEditor>> {
        match self.grid_editors.get(grid_id) {
            None => Err(FlowyError::internal().context("Should call open_grid function first")),
            Some(editor) => Ok(editor),
        }
    }

    async fn get_or_create_grid_editor(&self, grid_id: &str) -> FlowyResult<Arc<ClientGridEditor>> {
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
        let user = self.grid_user.clone();
        let rev_manager = self.make_grid_rev_manager(grid_id, pool.clone())?;
        let kv_persistence = self.get_kv_persistence()?;
        let grid_editor = ClientGridEditor::new(grid_id, user, rev_manager, kv_persistence).await?;
        self.grid_editors.insert(grid_id, &grid_editor);
        Ok(grid_editor)
    }

    fn make_grid_rev_manager(&self, grid_id: &str, pool: Arc<ConnectionPool>) -> FlowyResult<RevisionManager> {
        let user_id = self.grid_user.user_id()?;
        let rev_persistence = Arc::new(RevisionPersistence::new(&user_id, grid_id, pool));
        let rev_manager = RevisionManager::new(&user_id, grid_id, rev_persistence);
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

use lib_infra::uuid;
pub fn default_grid() -> String {
    let grid_id = uuid();
    let fields = vec![
        Field {
            id: uuid(),
            name: "".to_string(),
            desc: "".to_string(),
            field_type: FieldType::RichText,
            frozen: false,
            width: 100,
            type_options: Default::default(),
        },
        Field {
            id: uuid(),
            name: "".to_string(),
            desc: "".to_string(),
            field_type: FieldType::RichText,
            frozen: false,
            width: 100,
            type_options: Default::default(),
        },
    ];

    let rows = vec![
        RawRow {
            id: uuid(),
            grid_id: grid_id.clone(),
            cell_by_field_id: Default::default(),
        },
        RawRow {
            id: uuid(),
            grid_id: grid_id.clone(),
            cell_by_field_id: Default::default(),
        },
    ];

    make_grid(&grid_id, fields, rows)
}

pub fn make_grid(grid_id: &str, fields: Vec<Field>, rows: Vec<RawRow>) -> String {
    let field_orders = fields.iter().map(FieldOrder::from).collect::<Vec<_>>();
    let row_orders = rows.iter().map(RowOrder::from).collect::<Vec<_>>();

    let grid = Grid {
        id: grid_id.to_owned(),
        field_orders: field_orders.into(),
        row_orders: row_orders.into(),
    };
    let delta = make_grid_delta(&grid);
    delta.to_delta_str()
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
