use crate::{
    entities::doc::{Revision, RevisionRange},
    errors::DocError,
    sql_tables::{doc::RevTable, RevChangeset, RevState, RevTableType},
};
use diesel::update;
use flowy_database::{
    insert_or_ignore_into,
    prelude::*,
    schema::rev_table::{columns::*, dsl, dsl::doc_id},
    SqliteConnection,
};

pub struct RevTableSql {}

impl RevTableSql {
    pub(crate) fn create_rev_table(
        &self,
        revisions: Vec<(Revision, RevState)>,
        conn: &SqliteConnection,
    ) -> Result<(), DocError> {
        // Batch insert: https://diesel.rs/guides/all-about-inserts.html
        let records = revisions
            .into_iter()
            .map(|(revision, new_state)| {
                log::debug!("Set {} to {:?}", revision.rev_id, new_state);
                let rev_ty: RevTableType = revision.ty.into();
                (
                    doc_id.eq(revision.doc_id),
                    base_rev_id.eq(revision.base_rev_id),
                    rev_id.eq(revision.rev_id),
                    data.eq(revision.delta_data),
                    state.eq(new_state),
                    ty.eq(rev_ty),
                )
            })
            .collect::<Vec<_>>();

        let _ = insert_or_ignore_into(dsl::rev_table).values(&records).execute(conn)?;
        Ok(())
    }

    pub(crate) fn update_rev_table(&self, changeset: RevChangeset, conn: &SqliteConnection) -> Result<(), DocError> {
        let filter = dsl::rev_table
            .filter(rev_id.eq(changeset.rev_id.as_ref()))
            .filter(doc_id.eq(changeset.doc_id));
        let _ = update(filter).set(state.eq(changeset.state)).execute(conn)?;
        log::debug!("Set {} to {:?}", changeset.rev_id, changeset.state);
        Ok(())
    }

    pub(crate) fn read_rev_tables(
        &self,
        doc_id_s: &str,
        rev_id_s: Option<i64>,
        conn: &SqliteConnection,
    ) -> Result<Vec<Revision>, DocError> {
        let mut filter = dsl::rev_table
            .filter(doc_id.eq(doc_id_s))
            .order(rev_id.asc())
            .into_boxed();

        if let Some(rev_id_s) = rev_id_s {
            filter = filter.filter(rev_id.eq(rev_id_s))
        }

        let rev_tables = filter.load::<RevTable>(conn)?;

        let revisions = rev_tables
            .into_iter()
            .map(|table| table.into())
            .collect::<Vec<Revision>>();
        Ok(revisions)
    }

    pub(crate) fn read_rev_tables_with_range(
        &self,
        doc_id_s: &str,
        range: RevisionRange,
        conn: &SqliteConnection,
    ) -> Result<Vec<Revision>, DocError> {
        let rev_tables = dsl::rev_table
            .filter(rev_id.ge(range.start))
            .filter(rev_id.le(range.end))
            .filter(doc_id.eq(doc_id_s))
            .order(rev_id.asc())
            .load::<RevTable>(conn)?;

        let revisions = rev_tables
            .into_iter()
            .map(|table| table.into())
            .collect::<Vec<Revision>>();
        Ok(revisions)
    }

    pub(crate) fn delete_rev_table(
        &self,
        doc_id_s: &str,
        rev_id_s: i64,
        conn: &SqliteConnection,
    ) -> Result<(), DocError> {
        let filter = dsl::rev_table.filter(rev_id.eq(rev_id_s)).filter(doc_id.eq(doc_id_s));
        let affected_row = diesel::delete(filter).execute(conn)?;
        debug_assert_eq!(affected_row, 1);
        Ok(())
    }
}
