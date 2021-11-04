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
        tracing::debug!("Set {} to {:?}", changeset.rev_id, changeset.state);
        Ok(())
    }

    pub(crate) fn read_rev_tables(
        &self,
        did: &str,
        rid: Option<i64>,
        conn: &SqliteConnection,
    ) -> Result<Vec<Revision>, DocError> {
        let mut filter = dsl::rev_table.filter(doc_id.eq(did)).order(rev_id.asc()).into_boxed();
        if let Some(rid) = rid {
            filter = filter.filter(rev_id.eq(rid))
        }

        let rev_tables = filter.load::<RevTable>(conn)?;
        let revisions = rev_tables
            .into_iter()
            .map(|table| table.into())
            .collect::<Vec<Revision>>();
        Ok(revisions)
    }

    pub(crate) fn read_rev_table(
        &self,
        did: &str,
        rid: &i64,
        conn: &SqliteConnection,
    ) -> Result<Option<Revision>, DocError> {
        let filter = dsl::rev_table.filter(doc_id.eq(did)).filter(rev_id.eq(rid));
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

    #[allow(dead_code)]
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
