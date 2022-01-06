use crate::core::revision::{disk::DocumentRevisionDiskCache, RevisionRecord};
use bytes::Bytes;
use diesel::{sql_types::Integer, update, SqliteConnection};
use flowy_collaboration::{
    entities::revision::{RevId, RevType, Revision, RevisionRange, RevisionState},
    util::md5,
};
use flowy_database::{
    insert_or_ignore_into,
    prelude::*,
    schema::{rev_table, rev_table::dsl},
    ConnectionPool,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use std::sync::Arc;

pub struct SQLitePersistence {
    user_id: String,
    pub(crate) pool: Arc<ConnectionPool>,
}

impl DocumentRevisionDiskCache for SQLitePersistence {
    type Error = FlowyError;

    fn write_revision_records(
        &self,
        revisions: Vec<RevisionRecord>,
        conn: &SqliteConnection,
    ) -> Result<(), Self::Error> {
        let _ = RevisionTableSql::create(revisions, conn)?;
        Ok(())
    }

    fn read_revision_records(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        let records = RevisionTableSql::read(&self.user_id, doc_id, rev_ids, &*conn)?;
        Ok(records)
    }

    fn read_revision_records_with_range(
        &self,
        doc_id: &str,
        range: &RevisionRange,
    ) -> Result<Vec<RevisionRecord>, Self::Error> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        let revisions = RevisionTableSql::read_with_range(&self.user_id, doc_id, range.clone(), conn)?;
        Ok(revisions)
    }

    fn update_revision_record(&self, changesets: Vec<RevisionChangeset>) -> FlowyResult<()> {
        let conn = &*self.pool.get().map_err(internal_error)?;
        let _ = conn.immediate_transaction::<_, FlowyError, _>(|| {
            for changeset in changesets {
                let _ = RevisionTableSql::update(changeset, conn)?;
            }
            Ok(())
        })?;
        Ok(())
    }

    fn delete_revision_records(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
        conn: &SqliteConnection,
    ) -> Result<(), Self::Error> {
        let _ = RevisionTableSql::delete(doc_id, rev_ids, conn)?;
        Ok(())
    }

    fn reset_document(&self, doc_id: &str, revision_records: Vec<RevisionRecord>) -> Result<(), Self::Error> {
        let conn = self.pool.get().map_err(internal_error)?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let _ = self.delete_revision_records(doc_id, None, &*conn)?;
            let _ = self.write_revision_records(revision_records, &*conn)?;
            Ok(())
        })
    }
}

impl SQLitePersistence {
    pub(crate) fn new(user_id: &str, pool: Arc<ConnectionPool>) -> Self {
        Self {
            user_id: user_id.to_owned(),
            pool,
        }
    }
}

pub struct RevisionTableSql {}

impl RevisionTableSql {
    pub(crate) fn create(revision_records: Vec<RevisionRecord>, conn: &SqliteConnection) -> Result<(), FlowyError> {
        // Batch insert: https://diesel.rs/guides/all-about-inserts.html
        let records = revision_records
            .into_iter()
            .map(|record| {
                let rev_state: RevisionTableState = record.state.into();
                (
                    dsl::doc_id.eq(record.revision.doc_id),
                    dsl::base_rev_id.eq(record.revision.base_rev_id),
                    dsl::rev_id.eq(record.revision.rev_id),
                    dsl::data.eq(record.revision.delta_data),
                    dsl::state.eq(rev_state),
                    dsl::ty.eq(RevTableType::Local),
                )
            })
            .collect::<Vec<_>>();

        let _ = insert_or_ignore_into(dsl::rev_table).values(&records).execute(conn)?;
        Ok(())
    }

    pub(crate) fn update(changeset: RevisionChangeset, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let filter = dsl::rev_table
            .filter(dsl::rev_id.eq(changeset.rev_id.as_ref()))
            .filter(dsl::doc_id.eq(changeset.doc_id));
        let _ = update(filter).set(dsl::state.eq(changeset.state)).execute(conn)?;
        tracing::debug!("Set {} to {:?}", changeset.rev_id, changeset.state);
        Ok(())
    }

    pub(crate) fn read(
        user_id: &str,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
        conn: &SqliteConnection,
    ) -> Result<Vec<RevisionRecord>, FlowyError> {
        let mut sql = dsl::rev_table.filter(dsl::doc_id.eq(doc_id)).into_boxed();
        if let Some(rev_ids) = rev_ids {
            sql = sql.filter(dsl::rev_id.eq_any(rev_ids));
        }
        let rows = sql.order(dsl::rev_id.asc()).load::<RevisionTable>(conn)?;
        let records = rows
            .into_iter()
            .map(|row| mk_revision_record_from_table(user_id, row))
            .collect::<Vec<_>>();

        Ok(records)
    }

    pub(crate) fn read_with_range(
        user_id: &str,
        doc_id: &str,
        range: RevisionRange,
        conn: &SqliteConnection,
    ) -> Result<Vec<RevisionRecord>, FlowyError> {
        let rev_tables = dsl::rev_table
            .filter(dsl::rev_id.ge(range.start))
            .filter(dsl::rev_id.le(range.end))
            .filter(dsl::doc_id.eq(doc_id))
            .order(dsl::rev_id.asc())
            .load::<RevisionTable>(conn)?;

        let revisions = rev_tables
            .into_iter()
            .map(|table| mk_revision_record_from_table(user_id, table))
            .collect::<Vec<_>>();
        Ok(revisions)
    }

    pub(crate) fn delete(doc_id: &str, rev_ids: Option<Vec<i64>>, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let mut sql = dsl::rev_table.filter(dsl::doc_id.eq(doc_id)).into_boxed();
        if let Some(rev_ids) = rev_ids {
            sql = sql.filter(dsl::rev_id.eq_any(rev_ids));
        }

        let affected_row = sql.execute(conn)?;
        tracing::debug!("Delete {} revision rows", affected_row);
        Ok(())
    }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rev_table"]
pub(crate) struct RevisionTable {
    id: i32,
    pub(crate) doc_id: String,
    pub(crate) base_rev_id: i64,
    pub(crate) rev_id: i64,
    pub(crate) data: Vec<u8>,
    pub(crate) state: RevisionTableState,
    pub(crate) ty: RevTableType, // Deprecated
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum RevisionTableState {
    Local = 0,
    Ack   = 1,
}

impl std::default::Default for RevisionTableState {
    fn default() -> Self { RevisionTableState::Local }
}

impl std::convert::From<i32> for RevisionTableState {
    fn from(value: i32) -> Self {
        match value {
            0 => RevisionTableState::Local,
            1 => RevisionTableState::Ack,
            o => {
                log::error!("Unsupported rev state {}, fallback to RevState::Local", o);
                RevisionTableState::Local
            },
        }
    }
}

impl RevisionTableState {
    pub fn value(&self) -> i32 { *self as i32 }
}
impl_sql_integer_expression!(RevisionTableState);

impl std::convert::From<RevisionTableState> for RevisionState {
    fn from(s: RevisionTableState) -> Self {
        match s {
            RevisionTableState::Local => RevisionState::Local,
            RevisionTableState::Ack => RevisionState::Ack,
        }
    }
}

impl std::convert::From<RevisionState> for RevisionTableState {
    fn from(s: RevisionState) -> Self {
        match s {
            RevisionState::Local => RevisionTableState::Local,
            RevisionState::Ack => RevisionTableState::Ack,
        }
    }
}

pub(crate) fn mk_revision_record_from_table(user_id: &str, table: RevisionTable) -> RevisionRecord {
    let md5 = md5(&table.data);
    let revision = Revision::new(
        &table.doc_id,
        table.base_rev_id,
        table.rev_id,
        Bytes::from(table.data),
        &user_id,
        md5,
    );
    RevisionRecord {
        revision,
        state: table.state.into(),
        write_to_disk: false,
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash, FromSqlRow, AsExpression)]
#[repr(i32)]
#[sql_type = "Integer"]
pub enum RevTableType {
    Local  = 0,
    Remote = 1,
}

impl std::default::Default for RevTableType {
    fn default() -> Self { RevTableType::Local }
}

impl std::convert::From<i32> for RevTableType {
    fn from(value: i32) -> Self {
        match value {
            0 => RevTableType::Local,
            1 => RevTableType::Remote,
            o => {
                log::error!("Unsupported rev type {}, fallback to RevTableType::Local", o);
                RevTableType::Local
            },
        }
    }
}
impl RevTableType {
    pub fn value(&self) -> i32 { *self as i32 }
}
impl_sql_integer_expression!(RevTableType);

impl std::convert::From<RevType> for RevTableType {
    fn from(ty: RevType) -> Self {
        match ty {
            RevType::DeprecatedLocal => RevTableType::Local,
            RevType::DeprecatedRemote => RevTableType::Remote,
        }
    }
}

impl std::convert::From<RevTableType> for RevType {
    fn from(ty: RevTableType) -> Self {
        match ty {
            RevTableType::Local => RevType::DeprecatedLocal,
            RevTableType::Remote => RevType::DeprecatedRemote,
        }
    }
}

pub struct RevisionChangeset {
    pub(crate) doc_id: String,
    pub(crate) rev_id: RevId,
    pub(crate) state: RevisionTableState,
}
