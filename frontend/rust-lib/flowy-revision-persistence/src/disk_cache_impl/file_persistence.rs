use crate::{RevisionChangeset, RevisionDiskCache, SyncRecord};
use flowy_error::FlowyResult;
use flowy_http_model::revision::RevisionRange;

pub struct FileRevisionDiskCache {
    path: String,
}

pub type FileRevisionDiskCacheConnection = ();

impl RevisionDiskCache<FileRevisionDiskCacheConnection> for FileRevisionDiskCache {
    type Error = ();

    fn create_revision_records(&self, revision_records: Vec<SyncRecord>) -> Result<(), Self::Error> {
        Ok(())
    }

    fn get_connection(&self) -> Result<FileRevisionDiskCacheConnection, Self::Error> {
        return Ok(());
    }

    fn read_revision_records(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        Ok(vec![])
    }

    fn read_revision_records_with_range(
        &self,
        object_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        Ok(vec![])
    }

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()> {
        Ok(())
    }

    fn delete_revision_records(&self, object_id: &str, rev_ids: Option<Vec<i64>>) -> Result<(), Self::Error> {
        Ok(())
    }

    fn delete_and_insert_records(
        &self,
        object_id: &str,
        deleted_rev_ids: Option<Vec<i64>>,
        inserted_records: Vec<SyncRecord>,
    ) -> Result<(), Self::Error> {
        todo!()
    }
}
