use crate::{
    errors::FlowyError,
    services::doc::revision::RevisionRecord,
    sql_tables::{doc::RevTable, mk_revision_record_from_table, RevTableState, RevTableType, RevisionChangeset},
};
use diesel::update;
use flowy_collaboration::entities::revision::RevisionRange;
use flowy_database::{insert_or_ignore_into, prelude::*, schema::rev_table::dsl, SqliteConnection};

pub struct RevTableSql {}

impl RevTableSql {
    pub(crate) fn create_rev_table(revisions: Vec<RevisionRecord>, conn: &SqliteConnection) -> Result<(), FlowyError> {
        // Batch insert: https://diesel.rs/guides/all-about-inserts.html
        let records = revisions
            .into_iter()
            .map(|record| {
                let rev_ty: RevTableType = record.revision.ty.into();
                let rev_state: RevTableState = record.state.into();
                (
                    dsl::doc_id.eq(record.revision.doc_id),
                    dsl::base_rev_id.eq(record.revision.base_rev_id),
                    dsl::rev_id.eq(record.revision.rev_id),
                    dsl::data.eq(record.revision.delta_data),
                    dsl::state.eq(rev_state),
                    dsl::ty.eq(rev_ty),
                )
            })
            .collect::<Vec<_>>();

        let _ = insert_or_ignore_into(dsl::rev_table).values(&records).execute(conn)?;
        Ok(())
    }

    pub(crate) fn update_rev_table(changeset: RevisionChangeset, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let filter = dsl::rev_table
            .filter(dsl::rev_id.eq(changeset.rev_id.as_ref()))
            .filter(dsl::doc_id.eq(changeset.doc_id));
        let _ = update(filter).set(dsl::state.eq(changeset.state)).execute(conn)?;
        tracing::debug!("Set {} to {:?}", changeset.rev_id, changeset.state);
        Ok(())
    }

    pub(crate) fn read_rev_tables(
        user_id: &str,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
        conn: &SqliteConnection,
    ) -> Result<Vec<RevisionRecord>, FlowyError> {
        let mut sql = dsl::rev_table.filter(dsl::doc_id.eq(doc_id)).into_boxed();
        if let Some(rev_ids) = rev_ids {
            sql = sql.filter(dsl::rev_id.eq_any(rev_ids));
        }
        let rows = sql.order(dsl::rev_id.asc()).load::<RevTable>(conn)?;
        let records = rows
            .into_iter()
            .map(|row| mk_revision_record_from_table(user_id, row))
            .collect::<Vec<_>>();

        Ok(records)
    }

    pub(crate) fn read_rev_tables_with_range(
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
            .load::<RevTable>(conn)?;

        let revisions = rev_tables
            .into_iter()
            .map(|table| mk_revision_record_from_table(user_id, table))
            .collect::<Vec<_>>();
        Ok(revisions)
    }

    pub(crate) fn delete_rev_tables(
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
        conn: &SqliteConnection,
    ) -> Result<(), FlowyError> {
        let mut sql = dsl::rev_table.filter(dsl::doc_id.eq(doc_id)).into_boxed();
        if let Some(rev_ids) = rev_ids {
            sql = sql.filter(dsl::rev_id.eq_any(rev_ids));
        }

        let affected_row = sql.execute(conn)?;
        tracing::debug!("Delete {} revision rows", affected_row);
        Ok(())
    }
}
