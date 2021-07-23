use crate::{
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    sql_tables::{app::AppTable, view::ViewTable},
};
use flowy_database::{prelude::*, schema::view_table};
use std::sync::Arc;

pub struct ViewTableSql {
    pub database: Arc<dyn WorkspaceDatabase>,
}

impl ViewTableSql {
    pub(crate) fn create_view(&self, view_table: ViewTable) -> Result<(), WorkspaceError> {
        let conn = self.database.db_connection()?;
        let _ = diesel::insert_into(view_table::table)
            .values(view_table)
            .execute(&*conn)?;
        Ok(())
    }

    pub fn delete_view(&self, view_id: &str) -> Result<(), WorkspaceError> { unimplemented!() }
}
