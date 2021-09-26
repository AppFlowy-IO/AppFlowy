use crate::{
    errors::DocError,
    sql_tables::doc::{RevChangeset, RevTable},
};
use flowy_database::{
    prelude::*,
    schema::{rev_table, rev_table::dsl},
    SqliteConnection,
};

pub struct OpTableSql {}

impl OpTableSql {
    pub(crate) fn create_op_table(&self, op_table: RevTable, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = diesel::insert_into(rev_table::table).values(op_table).execute(conn)?;
        Ok(())
    }

    pub(crate) fn update_op_table(&self, changeset: RevChangeset, conn: &SqliteConnection) -> Result<(), DocError> {
        let filter = dsl::rev_table.filter(rev_table::dsl::rev_id.eq(changeset.rev_id));
        let affected_row = diesel::update(filter).set(changeset).execute(conn)?;
        debug_assert_eq!(affected_row, 1);
        Ok(())
    }

    pub(crate) fn read_op_table(&self, conn: &SqliteConnection) -> Result<Vec<RevTable>, DocError> {
        let ops = dsl::rev_table.load::<RevTable>(conn)?;
        Ok(ops)
    }

    pub(crate) fn delete_op_table(&self, rev_id: i64, conn: &SqliteConnection) -> Result<(), DocError> {
        let filter = dsl::rev_table.filter(rev_table::dsl::rev_id.eq(rev_id));
        let affected_row = diesel::delete(filter).execute(conn)?;
        debug_assert_eq!(affected_row, 1);
        Ok(())
    }
}
