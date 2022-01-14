mod version_1;
mod version_2;

use std::sync::Arc;
pub use version_1::{app_sql::*, trash_sql::*, v1_impl::V1Transaction, view_sql::*, workspace_sql::*};

use crate::module::WorkspaceDatabase;
use flowy_core_data_model::entities::{
    app::App,
    prelude::RepeatedTrash,
    trash::Trash,
    view::View,
    workspace::Workspace,
};
use flowy_error::{FlowyError, FlowyResult};

pub trait FlowyCorePersistenceTransaction {
    fn create_workspace(&self, user_id: &str, workspace: Workspace) -> FlowyResult<()>;
    fn read_workspaces(&self, user_id: &str, workspace_id: Option<String>) -> FlowyResult<Vec<Workspace>>;
    fn update_workspace(&self, changeset: WorkspaceChangeset) -> FlowyResult<()>;
    fn delete_workspace(&self, workspace_id: &str) -> FlowyResult<()>;

    fn create_app(&self, app: App) -> FlowyResult<()>;
    fn update_app(&self, changeset: AppChangeset) -> FlowyResult<()>;
    fn read_app(&self, app_id: &str) -> FlowyResult<App>;
    fn read_workspace_apps(&self, workspace_id: &str) -> FlowyResult<Vec<App>>;
    fn delete_app(&self, app_id: &str) -> FlowyResult<App>;

    fn create_view(&self, view: View) -> FlowyResult<()>;
    fn read_view(&self, view_id: &str) -> FlowyResult<View>;
    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>>;
    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()>;
    fn delete_view(&self, view_id: &str) -> FlowyResult<()>;

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()>;
    fn read_all_trash(&self) -> FlowyResult<RepeatedTrash>;
    fn delete_all_trash(&self) -> FlowyResult<()>;
    fn read_trash(&self, trash_id: &str) -> FlowyResult<Trash>;
    fn delete_trash(&self, trash_ids: Vec<String>) -> FlowyResult<()>;
}

pub struct FlowyCorePersistence {
    database: Arc<dyn WorkspaceDatabase>,
}

impl FlowyCorePersistence {
    pub fn new(database: Arc<dyn WorkspaceDatabase>) -> Self { Self { database } }

    pub fn begin_transaction<F, O>(&self, f: F) -> FlowyResult<O>
    where
        F: for<'a> FnOnce(Box<dyn FlowyCorePersistenceTransaction + 'a>) -> FlowyResult<O>,
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
}
