use crate::{
    errors::WorkspaceError,
    sql_tables::view::{ViewTable, ViewTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{view_table, view_table::dsl},
    SqliteConnection,
};

pub struct ViewTableSql {}

impl ViewTableSql {
    pub(crate) fn create_view(&self, view_table: ViewTable, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        let _ = diesel::insert_into(view_table::table).values(view_table).execute(conn)?;
        Ok(())
    }

    pub(crate) fn read_view(&self, view_id: &str, is_trash: Option<bool>, conn: &SqliteConnection) -> Result<ViewTable, WorkspaceError> {
        // https://docs.diesel.rs/diesel/query_builder/struct.UpdateStatement.html
        let mut filter = dsl::view_table.filter(view_table::id.eq(view_id)).into_boxed();
        if let Some(is_trash) = is_trash {
            filter = filter.filter(view_table::is_trash.eq(is_trash));
        }
        let view_table = filter.first::<ViewTable>(conn)?;
        Ok(view_table)
    }

    pub(crate) fn read_views_belong_to(&self, belong_to_id: &str, conn: &SqliteConnection) -> Result<Vec<ViewTable>, WorkspaceError> {
        let view_tables = dsl::view_table
            .filter(view_table::belong_to_id.eq(belong_to_id))
            .load::<ViewTable>(conn)?;

        Ok(view_tables)
    }

    pub(crate) fn update_view(&self, changeset: ViewTableChangeset, conn: &SqliteConnection) -> Result<(), WorkspaceError> {
        diesel_update_table!(view_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn delete_view(&self, view_id: &str, conn: &SqliteConnection) -> Result<ViewTable, WorkspaceError> {
        let view_table = dsl::view_table.filter(view_table::id.eq(view_id)).first::<ViewTable>(conn)?;
        diesel_delete_table!(view_table, view_id, conn);
        Ok(view_table)
    }
}
