use crate::{
    errors::DocError,
    sql_tables::{doc::RevTable, RevChangeset, RevTableType, SqlRevState},
};
use diesel::update;
use flowy_database::{insert_or_ignore_into, prelude::*, schema::rev_table::dsl, SqliteConnection};
use lib_ot::revision::{Revision, RevisionRange};

pub struct RevTableSql {}

impl RevTableSql {
    pub(crate) fn create_rev_table(
        &self,
        revisions: Vec<(Revision, SqlRevState)>,
        conn: &SqliteConnection,
    ) -> Result<(), DocError> {
        // Batch insert: https://diesel.rs/guides/all-about-inserts.html
        let records = revisions
            .into_iter()
            .map(|(revision, new_state)| {
                let rev_ty: RevTableType = revision.ty.into();
                (
                    dsl::doc_id.eq(revision.doc_id),
                    dsl::base_rev_id.eq(revision.base_rev_id),
                    dsl::rev_id.eq(revision.rev_id),
                    dsl::data.eq(revision.delta_data),
                    dsl::state.eq(new_state),
                    dsl::ty.eq(rev_ty),
                )
            })
            .collect::<Vec<_>>();

        let _ = insert_or_ignore_into(dsl::rev_table).values(&records).execute(conn)?;
        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) fn update_rev_table(&self, changeset: RevChangeset, conn: &SqliteConnection) -> Result<(), DocError> {
        let filter = dsl::rev_table
            .filter(dsl::rev_id.eq(changeset.rev_id.as_ref()))
            .filter(dsl::doc_id.eq(changeset.doc_id));
        let _ = update(filter).set(dsl::state.eq(changeset.state)).execute(conn)?;
        tracing::debug!("Set {} to {:?}", changeset.rev_id, changeset.state);
        Ok(())
    }

    pub(crate) fn read_rev_tables(&self, doc_id: &str, conn: &SqliteConnection) -> Result<Vec<Revision>, DocError> {
        let filter = dsl::rev_table
            .filter(dsl::doc_id.eq(doc_id))
            .order(dsl::rev_id.asc())
            .into_boxed();
        let rev_tables = filter.load::<RevTable>(conn)?;
        let revisions = rev_tables
            .into_iter()
            .map(|table| table.into())
            .collect::<Vec<Revision>>();
        Ok(revisions)
    }

    pub(crate) fn read_rev_table(
        &self,
        doc_id: &str,
        revision_id: &i64,
        conn: &SqliteConnection,
    ) -> Result<Option<Revision>, DocError> {
        let filter = dsl::rev_table
            .filter(dsl::doc_id.eq(doc_id))
            .filter(dsl::rev_id.eq(revision_id));
        let result = filter.first::<RevTable>(conn);

        if Err(diesel::NotFound) == result {
            Ok(None)
        } else {
            Ok(Some(result?.into()))
        }
    }

    pub(crate) fn read_rev_tables_with_range(
        &self,
        doc_id_s: &str,
        range: RevisionRange,
        conn: &SqliteConnection,
    ) -> Result<Vec<Revision>, DocError> {
        let rev_tables = dsl::rev_table
            .filter(dsl::rev_id.ge(range.start))
            .filter(dsl::rev_id.le(range.end))
            .filter(dsl::doc_id.eq(doc_id_s))
            .order(dsl::rev_id.asc())
            .load::<RevTable>(conn)?;

        let revisions = rev_tables
            .into_iter()
            .map(|table| table.into())
            .collect::<Vec<Revision>>();
        Ok(revisions)
    }

    #[allow(dead_code)]
    pub(crate) fn delete_rev_table(
        &self,
        doc_id_s: &str,
        rev_id_s: i64,
        conn: &SqliteConnection,
    ) -> Result<(), DocError> {
        let filter = dsl::rev_table
            .filter(dsl::rev_id.eq(rev_id_s))
            .filter(dsl::doc_id.eq(doc_id_s));
        let affected_row = diesel::delete(filter).execute(conn)?;
        debug_assert_eq!(affected_row, 1);
        Ok(())
    }
}
