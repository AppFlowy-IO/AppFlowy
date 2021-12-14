use crate::{
    errors::FlowyError,
    services::doc::revision::RevisionRecord,
    sql_tables::{doc::RevTable, mk_revision_record_from_table, RevChangeset, RevTableState, RevTableType},
};
use diesel::update;
use flowy_database::{insert_or_ignore_into, prelude::*, schema::rev_table::dsl, SqliteConnection};
use lib_ot::revision::RevisionRange;

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

    #[allow(dead_code)]
    pub(crate) fn update_rev_table(changeset: RevChangeset, conn: &SqliteConnection) -> Result<(), FlowyError> {
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
        conn: &SqliteConnection,
    ) -> Result<Vec<RevisionRecord>, FlowyError> {
        let filter = dsl::rev_table
            .filter(dsl::doc_id.eq(doc_id))
            .order(dsl::rev_id.asc())
            .into_boxed();
        let rev_tables = filter.load::<RevTable>(conn)?;
        let revisions = rev_tables
            .into_iter()
            .map(|table| mk_revision_record_from_table(user_id, table))
            .collect::<Vec<_>>();
        Ok(revisions)
    }

    pub(crate) fn read_rev_table(
        user_id: &str,
        doc_id: &str,
        revision_id: &i64,
        conn: &SqliteConnection,
    ) -> Result<Option<RevisionRecord>, FlowyError> {
        let filter = dsl::rev_table
            .filter(dsl::doc_id.eq(doc_id))
            .filter(dsl::rev_id.eq(revision_id));
        let result = filter.first::<RevTable>(conn);

        if Err(diesel::NotFound) == result {
            Ok(None)
        } else {
            Ok(Some(mk_revision_record_from_table(user_id, result?)))
        }
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

    #[allow(dead_code)]
    pub(crate) fn delete_rev_table(doc_id_s: &str, rev_id_s: i64, conn: &SqliteConnection) -> Result<(), FlowyError> {
        let filter = dsl::rev_table
            .filter(dsl::rev_id.eq(rev_id_s))
            .filter(dsl::doc_id.eq(doc_id_s));
        let affected_row = diesel::delete(filter).execute(conn)?;
        debug_assert_eq!(affected_row, 1);
        Ok(())
    }
}
