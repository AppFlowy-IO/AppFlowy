use bytes::Bytes;
use diesel::{sql_types::Integer, update, SqliteConnection};
use flowy_database::{
    impl_sql_integer_expression, insert_or_ignore_into,
    prelude::*,
    schema::{grid_view_rev_table, grid_view_rev_table::dsl},
    ConnectionPool,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_http_model::revision::{Revision, RevisionRange};
use flowy_http_model::util::md5;
use flowy_revision_persistence::{RevisionChangeset, RevisionDiskCache, RevisionState, SyncRecord};
use std::sync::Arc;

pub struct SQLiteGridViewRevisionPersistence {
    user_id: String,
    pub(crate) pool: Arc<ConnectionPool>,
}

impl SQLiteGridViewRevisionPersistence {
    pub fn new(user_id: &str, pool: Arc<ConnectionPool>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            pool,
        }
    }
}

impl RevisionDiskCache<Arc<ConnectionPool>> for SQLiteGridViewRevisionPersistence {
    type Error = FlowyError;

    fn create_revision_records(&self, revision_records: Vec<SyncRecord>) -> Result<(), Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        GridViewRevisionSql::create(revision_records, &conn)?;
        Ok(())
    }

    fn get_connection(&self) -> Result<Arc<ConnectionPool>, Self::Error> {
        Ok(self.pool.clone())
    }

    fn read_revision_records(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let records = GridViewRevisionSql::read(&self.user_id, object_id, rev_ids, &conn)?;
        Ok(records)
    }

    fn read_revision_records_with_range(
        &self,
        object_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<SyncRecord>, Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        let revisions = GridViewRevisionSql::read_with_range(&self.user_id, object_id, range.clone(), conn)?;
        Ok(revisions)
    }

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            for changeset in changesets {
                GridViewRevisionSql::update(changeset, conn)?;
            }
            Ok(())
        })?;
        Ok(())
    }

    fn delete_revision_records(&self, object_id: &str, rev_ids: Option<Vec<i64>>) -> Result<(), Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        GridViewRevisionSql::delete(object_id, rev_ids, conn)?;
        Ok(())
    }

    fn delete_and_insert_records(
        &self,
        object_id: &str,
        deleted_rev_ids: Option<Vec<i64>>,
        inserted_records: Vec<SyncRecord>,
    ) -> Result<(), Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            GridViewRevisionSql::delete(object_id, deleted_rev_ids, &conn)?;
            GridViewRevisionSql::create(inserted_records, &conn)?;
            Ok(())
        })
    }
}

struct GridViewRevisionSql();
impl GridViewRevisionSql {
    fn create(revision_records: Vec<SyncRecord>, conn: &SqliteConnection) -> Result<(), FlowyError> {
        // Batch insert: https://diesel.rs/guides/all-about-inserts.html
        let records = revision_records
            .into_iter()
            .map(|record| {
                tracing::trace!(
                    "[GridViewRevisionSql] create revision: {}:{:?}",
                    record.revision.object_id,
                    record.revision.rev_id
                );
                let rev_state: GridViewRevisionState = record.state.into();
                (
                    dsl::object_id.eq(record.revision.object_id),
                    dsl::base_rev_id.eq(record.revision.base_rev_id),
                    dsl::rev_id.eq(record.revision.rev_id),
                    dsl::data.eq(record.revision.bytes),
                    dsl::state.eq(rev_state),
                )
            })
            .collect::<Vec<_>>();

        let _ = insert_or_ignore_into(dsl::grid_view_rev_table)
            .values(&records)
            .execute(conn)?;
        Ok(())
    }

    fn update(changeset: RevisionChangeset, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let state: GridViewRevisionState = changeset.state.clone().into();
        let filter = dsl::grid_view_rev_table
            .filter(dsl::rev_id.eq(changeset.rev_id))
            .filter(dsl::object_id.eq(changeset.object_id));
        let _ = update(filter).set(dsl::state.eq(state)).execute(conn)?;
        tracing::debug!(
            "[GridViewRevisionSql] update revision:{} state:to {:?}",
            changeset.rev_id,
            changeset.state
        );
        Ok(())
    }

    fn read(
        user_id: &str,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
        conn: &SqliteConnection,
    ) -> Result<Vec<SyncRecord>, FlowyError> {
        let mut sql = dsl::grid_view_rev_table
            .filter(dsl::object_id.eq(object_id))
            .into_boxed();
        if let Some(rev_ids) = rev_ids {
            sql = sql.filter(dsl::rev_id.eq_any(rev_ids));
        }
        let rows = sql.order(dsl::rev_id.asc()).load::<GridViewRevisionTable>(conn)?;
        let records = rows
            .into_iter()
            .map(|row| mk_revision_record_from_table(user_id, row))
            .collect::<Vec<_>>();

        Ok(records)
    }

    fn read_with_range(
        user_id: &str,
        object_id: &str,
        range: RevisionRange,
        conn: &SqliteConnection,
    ) -> Result<Vec<SyncRecord>, FlowyError> {
        let rev_tables = dsl::grid_view_rev_table
            .filter(dsl::rev_id.ge(range.start))
            .filter(dsl::rev_id.le(range.end))
            .filter(dsl::object_id.eq(object_id))
            .order(dsl::rev_id.asc())
            .load::<GridViewRevisionTable>(conn)?;

        let revisions = rev_tables
            .into_iter()
            .map(|table| mk_revision_record_from_table(user_id, table))
            .collect::<Vec<_>>();
        Ok(revisions)
    }

    fn delete(object_id: &str, rev_ids: Option<Vec<i64>>, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let mut sql = diesel::delete(dsl::grid_view_rev_table).into_boxed();
        sql = sql.filter(dsl::object_id.eq(object_id));

        if let Some(rev_ids) = rev_ids {
            tracing::trace!("[GridViewRevisionSql] Delete revision: {}:{:?}", object_id, rev_ids);
            sql = sql.filter(dsl::rev_id.eq_any(rev_ids));
        }

        let affected_row = sql.execute(conn)?;
        tracing::trace!("[GridViewRevisionSql] Delete {} rows", affected_row);
        Ok(())
    }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "grid_view_rev_table"]
struct GridViewRevisionTable {
    id: i32,
    object_id: String,
    base_rev_id: i64,
    rev_id: i64,
    data: Vec<u8>,
    state: GridViewRevisionState,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum GridViewRevisionState {
    Sync = 0,
    Ack = 1,
}
impl_sql_integer_expression!(GridViewRevisionState);
impl_rev_state_map!(GridViewRevisionState);

impl std::default::Default for GridViewRevisionState {
    fn default() -> Self {
        GridViewRevisionState::Sync
    }
}

fn mk_revision_record_from_table(_user_id: &str, table: GridViewRevisionTable) -> SyncRecord {
    let md5 = md5(&table.data);
    let revision = Revision::new(
        &table.object_id,
        table.base_rev_id,
        table.rev_id,
        Bytes::from(table.data),
        md5,
    );
    SyncRecord {
        revision,
        state: table.state.into(),
        write_to_disk: false,
    }
}
