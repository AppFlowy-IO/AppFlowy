use crate::manager::FolderId;
use crate::{
    event_map::WorkspaceDatabase,
    services::persistence::{AppTableSql, TrashTableSql, ViewTableSql, WorkspaceTableSql},
};
use bytes::Bytes;
use flowy_database::kv::KV;
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder_data_model::revision::{AppRevision, FolderRevision, ViewRevision, WorkspaceRevision};
use flowy_revision::disk::SQLiteDocumentRevisionPersistence;
use flowy_revision::reset::{RevisionResettable, RevisionStructReset};
use flowy_sync::client_folder::make_folder_rev_json_str;
use flowy_sync::entities::revision::Revision;
use flowy_sync::server_folder::FolderOperationsBuilder;
use flowy_sync::{client_folder::FolderPad, entities::revision::md5};

use std::sync::Arc;

const V1_MIGRATION: &str = "FOLDER_V1_MIGRATION";
const V2_MIGRATION: &str = "FOLDER_V2_MIGRATION";
#[allow(dead_code)]
const V3_MIGRATION: &str = "FOLDER_V3_MIGRATION";

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
        let key = migration_flag_key(&self.user_id, V1_MIGRATION);
        if KV::get_bool(&key) {
            return Ok(None);
        }

        let pool = self.database.db_pool()?;
        let conn = &*pool.get()?;
        let workspaces = conn.immediate_transaction::<_, FlowyError, _>(|| {
            let mut workspaces = WorkspaceTableSql::read_workspaces(&self.user_id, None, conn)?
                .into_iter()
                .map(WorkspaceRevision::from)
                .collect::<Vec<_>>();

            for workspace in workspaces.iter_mut() {
                let mut apps = AppTableSql::read_workspace_apps(&workspace.id, conn)?
                    .into_iter()
                    .map(AppRevision::from)
                    .collect::<Vec<_>>();

                for app in apps.iter_mut() {
                    let views = ViewTableSql::read_views(&app.id, conn)?
                        .into_iter()
                        .map(ViewRevision::from)
                        .collect::<Vec<_>>();

                    app.belongings = views;
                }

                workspace.apps = apps;
            }
            Ok(workspaces)
        })?;

        if workspaces.is_empty() {
            tracing::trace!("Run folder v1 migration, but workspace is empty");
            KV::set_bool(&key, true);
            return Ok(None);
        }

        let trash = conn.immediate_transaction::<_, FlowyError, _>(|| {
            let trash = TrashTableSql::read_all(conn)?;
            Ok(trash)
        })?;

        let folder = FolderPad::new(workspaces, trash)?;
        KV::set_bool(&key, true);
        tracing::info!("Run folder v1 migration");
        Ok(Some(folder))
    }

    pub async fn run_v2_migration(&self, folder_id: &FolderId) -> FlowyResult<()> {
        let key = migration_flag_key(&self.user_id, V2_MIGRATION);
        if KV::get_bool(&key) {
            return Ok(());
        }
        let _ = self.migration_folder_rev_struct(folder_id).await?;
        KV::set_bool(&key, true);
        // tracing::info!("Run folder v2 migration");
        Ok(())
    }

    pub async fn run_v3_migration(&self, folder_id: &FolderId) -> FlowyResult<()> {
        let key = migration_flag_key(&self.user_id, V3_MIGRATION);
        if KV::get_bool(&key) {
            return Ok(());
        }
        let _ = self.migration_folder_rev_struct(folder_id).await?;
        KV::set_bool(&key, true);
        tracing::info!("Run folder v3 migration");
        Ok(())
    }

    pub async fn migration_folder_rev_struct(&self, folder_id: &FolderId) -> FlowyResult<()> {
        let object = FolderRevisionResettable {
            folder_id: folder_id.as_ref().to_owned(),
        };

        let pool = self.database.db_pool()?;
        let disk_cache = SQLiteDocumentRevisionPersistence::new(&self.user_id, pool);
        let reset = RevisionStructReset::new(&self.user_id, object, Arc::new(disk_cache));
        reset.run().await
    }
}

fn migration_flag_key(user_id: &str, version: &str) -> String {
    md5(format!("{}{}", user_id, version,))
}

pub struct FolderRevisionResettable {
    folder_id: String,
}

impl RevisionResettable for FolderRevisionResettable {
    fn target_id(&self) -> &str {
        &self.folder_id
    }

    fn reset_data(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let pad = FolderPad::from_revisions(revisions)?;
        let json = pad.to_json()?;
        let bytes = FolderOperationsBuilder::new().insert(&json).build().json_bytes();
        Ok(bytes)
    }

    fn default_target_rev_str(&self) -> FlowyResult<String> {
        let folder = FolderRevision::default();
        let json = make_folder_rev_json_str(&folder)?;
        Ok(json)
    }
}
