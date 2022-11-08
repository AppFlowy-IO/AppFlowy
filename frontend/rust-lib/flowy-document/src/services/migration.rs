use crate::services::delta_migration::DeltaRevisionMigration;
use crate::services::rev_sqlite::{DeltaRevisionSql, SQLiteDocumentRevisionPersistence};
use crate::DocumentDatabase;
use bytes::Bytes;
use flowy_database::kv::KV;
use flowy_error::FlowyResult;
use flowy_revision::disk::{RevisionDiskCache, SyncRecord};
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::{make_operations_from_revisions, md5};
use std::sync::Arc;

const V1_MIGRATION: &str = "DOCUMENT_V1_MIGRATION";
pub(crate) struct DocumentMigration {
    user_id: String,
    database: Arc<dyn DocumentDatabase>,
}

impl DocumentMigration {
    pub fn new(user_id: &str, database: Arc<dyn DocumentDatabase>) -> Self {
        let user_id = user_id.to_owned();
        Self { user_id, database }
    }

    pub fn run_v1_migration(&self) -> FlowyResult<()> {
        let key = migration_flag_key(&self.user_id, V1_MIGRATION);
        if KV::get_bool(&key) {
            return Ok(());
        }

        let pool = self.database.db_pool()?;
        let conn = &*pool.get()?;
        let disk_cache = SQLiteDocumentRevisionPersistence::new(&self.user_id, pool);
        let documents = DeltaRevisionSql::read_all_documents(&self.user_id, conn)?;
        tracing::debug!("[Document Migration]: try migrate {} documents", documents.len());
        for revisions in documents {
            if revisions.is_empty() {
                continue;
            }

            let document_id = revisions.first().unwrap().object_id.clone();
            match make_operations_from_revisions(revisions) {
                Ok(delta) => match DeltaRevisionMigration::run(delta) {
                    Ok(transaction) => {
                        let bytes = Bytes::from(transaction.to_bytes()?);
                        let md5 = format!("{:x}", md5::compute(&bytes));
                        let revision = Revision::new(&document_id, 0, 1, bytes, md5);
                        let record = SyncRecord::new(revision);
                        match disk_cache.create_revision_records(vec![record]) {
                            Ok(_) => {}
                            Err(err) => {
                                tracing::error!("[Document Migration]: Save revisions to disk failed {:?}", err);
                            }
                        }
                    }
                    Err(err) => {
                        tracing::error!(
                            "[Document Migration]: Migrate revisions to transaction failed {:?}",
                            err
                        );
                    }
                },
                Err(e) => {
                    tracing::error!("[Document migration]: Make delta from revisions failed: {:?}", e);
                }
            }
        }
        //

        KV::set_bool(&key, true);
        tracing::debug!("Run document v1 migration");
        Ok(())
    }
}
fn migration_flag_key(user_id: &str, version: &str) -> String {
    md5(format!("{}{}", user_id, version,))
}
