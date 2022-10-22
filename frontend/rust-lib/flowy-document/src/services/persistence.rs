use crate::services::migration::DocumentMigration;
use crate::DocumentDatabase;
use flowy_error::FlowyResult;
use std::sync::Arc;

pub struct DocumentPersistence {
    pub database: Arc<dyn DocumentDatabase>,
}

impl DocumentPersistence {
    pub fn new(database: Arc<dyn DocumentDatabase>) -> Self {
        Self { database }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    pub fn initialize(&self, user_id: &str) -> FlowyResult<()> {
        let migration = DocumentMigration::new(user_id, self.database.clone());
        if let Err(e) = migration.run_v1_migration() {
            tracing::error!("[Document Migration]: run v1 migration failed: {:?}", e);
        }
        Ok(())
    }
}
