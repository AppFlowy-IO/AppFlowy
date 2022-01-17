pub mod version_1;
mod version_2;

use parking_lot::RwLock;
use std::sync::Arc;
pub use version_1::{app_sql::*, trash_sql::*, v1_impl::V1Transaction, view_sql::*, workspace_sql::*};

use crate::{
    module::{WorkspaceDatabase, WorkspaceUser},
    services::persistence::version_2::v2_impl::FolderEditor,
};
use flowy_core_data_model::entities::{
    app::App,
    prelude::RepeatedTrash,
    trash::Trash,
    view::View,
    workspace::Workspace,
};
use flowy_error::{FlowyError, FlowyResult};

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

    fn create_view(&self, view: View) -> FlowyResult<()>;
    fn read_view(&self, view_id: &str) -> FlowyResult<View>;
    fn read_views(&self, belong_to_id: &str) -> FlowyResult<Vec<View>>;
    fn update_view(&self, changeset: ViewChangeset) -> FlowyResult<()>;
    fn delete_view(&self, view_id: &str) -> FlowyResult<()>;

    fn create_trash(&self, trashes: Vec<Trash>) -> FlowyResult<()>;
    fn read_trash(&self, trash_id: Option<String>) -> FlowyResult<RepeatedTrash>;
    fn delete_trash(&self, trash_ids: Option<Vec<String>>) -> FlowyResult<()>;
}

pub struct FolderPersistence {
    user: Arc<dyn WorkspaceUser>,
    database: Arc<dyn WorkspaceDatabase>,
    folder_editor: RwLock<Option<Arc<FolderEditor>>>,
}

impl FolderPersistence {
    pub fn new(user: Arc<dyn WorkspaceUser>, database: Arc<dyn WorkspaceDatabase>) -> Self {
        let folder_editor = RwLock::new(None);
        Self {
            user,
            database,
            folder_editor,
        }
    }

    pub fn begin_transaction<F, O>(&self, f: F) -> FlowyResult<O>
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

    pub fn begin_transaction2<F, O>(&self, f: F) -> FlowyResult<O>
    where
        F: FnOnce(Arc<dyn FolderPersistenceTransaction>) -> FlowyResult<O>,
    {
        match self.folder_editor.read().clone() {
            None => Err(FlowyError::internal()),
            Some(editor) => f(editor),
        }
    }

    pub fn user_did_logout(&self) {
        // let user_id = user.user_id()?;
        // let pool = database.db_pool()?;
        // let folder_editor = Arc::new(FolderEditor::new(&user_id, pool)?);
        *self.folder_editor.write() = None;
    }

    pub async fn user_did_login(&self) -> FlowyResult<()> {
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let pool = self.database.db_pool()?;
        let folder_editor = FolderEditor::new(&user_id, &token, pool).await?;
        *self.folder_editor.write() = Some(Arc::new(folder_editor));
        Ok(())
    }
}
