use crate::manager::FolderId;
use crate::{
    event_map::WorkspaceDatabase,
    services::persistence::{AppTableSql, TrashTableSql, ViewTableSql, WorkspaceTableSql},
};
use flowy_database::kv::KV;
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_data_model::entities::{
    app::{App, RepeatedApp},
    view::{RepeatedView, View},
    workspace::Workspace,
};
use flowy_revision::disk::SQLiteTextBlockRevisionPersistence;
use flowy_revision::{RevisionLoader, RevisionPersistence};
use flowy_sync::{client_folder::FolderPad, entities::revision::md5};
use std::sync::Arc;

const V1_MIGRATION: &str = "FOLDER_V1_MIGRATION";
const V2_MIGRATION: &str = "FOLDER_V2_MIGRATION";

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
        if KV::get_bool(&key) {
            return Ok(None);
        }

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
            tracing::trace!("Run folder v1 migration, but workspace is empty");
            KV::set_bool(&key, true);
            return Ok(None);
        }

        let trash = conn.immediate_transaction::<_, FlowyError, _>(|| {
            let trash = TrashTableSql::read_all(conn)?.take_items();
            Ok(trash)
        })?;

        let folder = FolderPad::new(workspaces, trash)?;
        KV::set_bool(&key, true);
        tracing::trace!("Run folder v1 migration");
        Ok(Some(folder))
    }

    pub async fn run_v2_migration(&self, user_id: &str, folder_id: &FolderId) -> FlowyResult<Option<FolderPad>> {
        let key = md5(format!("{}{}", self.user_id, V2_MIGRATION));
        if KV::get_bool(&key) {
            return Ok(None);
        }
        let pool = self.database.db_pool()?;
        let disk_cache = SQLiteTextBlockRevisionPersistence::new(user_id, pool);
        let rev_persistence = Arc::new(RevisionPersistence::new(user_id, folder_id.as_ref(), disk_cache));
        let (revisions, _) = RevisionLoader {
            object_id: folder_id.as_ref().to_owned(),
            user_id: self.user_id.clone(),
            cloud: None,
            rev_persistence,
        }
        .load()
        .await?;

        if revisions.is_empty() {
            tracing::trace!("Run folder v2 migration, but revision is empty");
            KV::set_bool(&key, true);
            return Ok(None);
        }

        let pad = FolderPad::from_revisions(revisions)?;
        KV::set_bool(&key, true);
        tracing::trace!("Run folder v2 migration");
        Ok(Some(pad))
    }
}
