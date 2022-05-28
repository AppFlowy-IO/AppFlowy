mod migration;
pub mod version_1;
mod version_2;

use crate::{
    event_map::WorkspaceDatabase,
    manager::FolderId,
    services::{folder_editor::FolderEditor, persistence::migration::FolderMigration},
};
use flowy_database::ConnectionPool;
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_data_model::entities::{
    app::App,
    trash::{RepeatedTrash, Trash},
    view::View,
    workspace::Workspace,
};
use flowy_revision::disk::{RevisionRecord, RevisionState};
use flowy_revision::mk_revision_disk_cache;
use flowy_sync::client_folder::initial_folder_delta;
use flowy_sync::{client_folder::FolderPad, entities::revision::Revision};
use std::sync::Arc;
use tokio::sync::RwLock;
pub use version_1::{app_sql::*, trash_sql::*, v1_impl::V1Transaction, view_sql::*, workspace_sql::*};

pub trait FolderPersistenceTransaction {
    fn create_workspace(&self, user_id: &str, workspace: Workspace) -> FlowyResult<()>;
    fn read_workspaces(&self, user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<Workspace>>;
    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()>;
    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()>;

    fn create_app(&self, app: App) -> FlowyResult<()>;
    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()>;
    fn read_app(&self, app_id: &str) -> FlowyResult<App>;
    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<App>>;
    fn delete_app(&self, app_id: &str) -> FlowyResult<App>;
    fn move_app(&self, app_id: &str, from: usize, to: usize) -> FlowyResult<()>;

    fn create_view(&self, view: View) -> FlowyResult<()>;
    fn read_view(&self, view_id: &str) -> FlowyResult<View>;
    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>>;
    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()>;
    fn delete_view(&self, view_id: &str) -> FlowyResult<()>;
    fn move_view(&self, view_id: &str, from: usize, to: usize) -> FlowyResult<()>;

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()>;
    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<RepeatedTrash>;
    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()>;
}

pub struct FolderPersistence {
    database: Arc<dyn WorkspaceDatabase>,
    folder_editor: Arc<RwLock<Option<Arc<FolderEditor>>>>,
}

impl FolderPersistence {
    pub fn new(database: Arc<dyn WorkspaceDatabase>, folder_editor: Arc<RwLock<Option<Arc<FolderEditor>>>>) -> Self {
        Self {
            database,
            folder_editor,
        }
    }

    #[deprecated(
        since = "0.0.3",
        note = "please use `begin_transaction` instead, this interface will be removed in the future"
    )]
    #[allow(dead_code)]
    pub fn begin_transaction_v_1<F, O>(&self, f: F) -> FlowyResult<O>
    where
        F: for<'a> FnOnce(Box<dyn FolderPersistenceTransaction + 'a>) -> FlowyResult<O>,
    {
        //[[immediate_transaction]]
        // https://sqlite.org/lang_transaction.html
        // IMMEDIATE cause the database connection to start a new write immediately,
        // without waiting for a write statement. The BEGIN IMMEDIATE might fail
        // with SQLITE_BUSY if another write transaction is already active on another
        // database connection.
        //
        // EXCLUSIVE is similar to IMMEDIATE in that a write transaction is started
        // immediately. EXCLUSIVE and IMMEDIATE are the same in WAL mode, but in
        // other journaling modes, EXCLUSIVE prevents other database connections from
        // reading the database while the transaction is underway.
        let conn = self.database.db_connection()?;
        conn.immediate_transaction::<_, FlowyError, _>(|| f(Box::new(V1Transaction(&conn))))
    }

    pub async fn begin_transaction<F, O>(&self, f: F) -> FlowyResult<O>
    where
        F: FnOnce(Arc<dyn FolderPersistenceTransaction>) -> FlowyResult<O>,
    {
        match self.folder_editor.read().await.clone() {
            None => Err(FlowyError::internal().context("FolderEditor should be initialized after user login in.")),
            Some(editor) => f(editor),
        }
    }

    pub fn db_pool(&self) -> FlowyResult<Arc<ConnectionPool>> {
        self.database.db_pool()
    }

    pub async fn initialize(&self, user_id: &str, folder_id: &FolderId) -> FlowyResult<()> {
        let migrations = FolderMigration::new(user_id, self.database.clone());
        if let Some(migrated_folder) = migrations.run_v1_migration()? {
            self.save_folder(user_id, folder_id, migrated_folder).await?;
        }

        if let Some(migrated_folder) = migrations.run_v2_migration(user_id, folder_id).await? {
            self.save_folder(user_id, folder_id, migrated_folder).await?;
        }

        Ok(())
    }

    pub async fn save_folder(&self, user_id: &str, folder_id: &FolderId, folder: FolderPad) -> FlowyResult<()> {
        let pool = self.database.db_pool()?;
        let delta_data = initial_folder_delta(&folder)?.to_delta_bytes();
        let md5 = folder.md5();
        let revision = Revision::new(folder_id.as_ref(), 0, 0, delta_data, user_id, md5);
        let record = RevisionRecord {
            revision,
            state: RevisionState::Sync,
            write_to_disk: true,
        };

        let disk_cache = mk_revision_disk_cache(user_id, pool);
        disk_cache.delete_and_insert_records(folder_id.as_ref(), None, vec![record])
    }
}
