use crate::{
    entities::view::{RepeatedView, View},
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
        match diesel_record_count!(view_table, &view_table.id, conn) {
            0 => diesel_insert_table!(view_table, &view_table, conn),
            _ => {
                let changeset = ViewTableChangeset::from_table(view_table);
                diesel_update_table!(view_table, changeset, conn)
            },
        }
        Ok(())
    }

    pub(crate) fn read_view(
        &self,
        view_id: &str,
        is_trash: Option<bool>,
        conn: &SqliteConnection,
    ) -> Result<ViewTable, WorkspaceError> {
        // https://docs.diesel.rs/diesel/query_builder/struct.UpdateStatement.html
        let mut filter = dsl::view_table.filter(view_table::id.eq(view_id)).into_boxed();
        if let Some(is_trash) = is_trash {
            filter = filter.filter(view_table::is_trash.eq(is_trash));
        }
        let view_table = filter.first::<ViewTable>(conn)?;
        Ok(view_table)
    }

    // belong_to_id will be the app_id or view_id.
    pub(crate) fn read_views_belong_to(
        &self,
        belong_to_id: &str,
        is_trash: Option<bool>,
        conn: &SqliteConnection,
    ) -> Result<RepeatedView, WorkspaceError> {
        let mut filter = dsl::view_table
            .filter(view_table::belong_to_id.eq(belong_to_id))
            .into_boxed();
        if let Some(is_trash) = is_trash {
            filter = filter.filter(view_table::is_trash.eq(is_trash));
        }
        let view_tables = filter.load::<ViewTable>(conn)?;

        let views = view_tables
            .into_iter()
            .map(|view_table| view_table.into())
            .collect::<Vec<View>>();

        Ok(RepeatedView { items: views })
    }

    pub(crate) fn update_view(
        &self,
        changeset: ViewTableChangeset,
        conn: &SqliteConnection,
    ) -> Result<(), WorkspaceError> {
        diesel_update_table!(view_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn delete_view(&self, view_id: &str, conn: &SqliteConnection) -> Result<ViewTable, WorkspaceError> {
        let view_table = dsl::view_table
            .filter(view_table::id.eq(view_id))
            .first::<ViewTable>(conn)?;
        diesel_delete_table!(view_table, view_id, conn);
        Ok(view_table)
    }
}
