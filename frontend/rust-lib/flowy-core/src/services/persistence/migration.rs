use crate::{
    module::WorkspaceDatabase,
    services::persistence::{AppTableSql, TrashTableSql, ViewTableSql, WorkspaceTableSql, FOLDER_ID},
};
use flowy_collaboration::{
    entities::revision::{md5, Revision},
    folder::FolderPad,
};
use flowy_core_data_model::entities::{
    app::{App, RepeatedApp},
    view::{RepeatedView, View},
    workspace::Workspace,
};
use flowy_database::kv::KV;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::{RevisionCache, RevisionManager};
use std::sync::Arc;

pub(crate) const V1_MIGRATION: &str = "FOLDER_V1_MIGRATION";

pub(crate) struct FolderMigration {
    user_id: String,
    database: Arc<dyn WorkspaceDatabase>,
}

impl FolderMigration {
    pub fn new(user_id: &str, database: Arc<dyn WorkspaceDatabase>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            database,
        }
    }

    pub fn run_v1_migration(&self) -> FlowyResult<Option<FolderPad>> {
        let key = md5(format!("{}{}", self.user_id, V1_MIGRATION));
        if KV::get_bool(&key).unwrap_or(false) {
            return Ok(None);
        }
        tracing::trace!("Run folder version 1 migrations");
        let pool = self.database.db_pool()?;
        let conn = &*pool.get()?;
        let workspaces = conn.immediate_transaction::<_, FlowyError, _>(|| {
            let mut workspaces = WorkspaceTableSql::read_workspaces(&self.user_id, None, conn)?
                .into_iter()
                .map(Workspace::from)
                .collect::<Vec<_>>();

            for workspace in workspaces.iter_mut() {
                let mut apps = AppTableSql::read_workspace_apps(&workspace.id, conn)?
                    .into_iter()
                    .map(App::from)
                    .collect::<Vec<_>>();

                for app in apps.iter_mut() {
                    let views = ViewTableSql::read_views(&app.id, conn)?
                        .into_iter()
                        .map(View::from)
                        .collect::<Vec<_>>();

                    app.belongings = RepeatedView { items: views };
                }

                workspace.apps = RepeatedApp { items: apps };
            }
            Ok(workspaces)
        })?;

        if workspaces.is_empty() {
            return Ok(None);
        }

        let trash = conn.immediate_transaction::<_, FlowyError, _>(|| {
            let trash = TrashTableSql::read_all(conn)?.take_items();
            Ok(trash)
        })?;

        let folder = FolderPad::new(workspaces, trash)?;
        KV::set_bool(&key, true);
        Ok(Some(folder))
    }
}
