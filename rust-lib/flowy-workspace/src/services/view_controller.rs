use crate::{
    entities::view::{CreateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceUser,
    sql_tables::view::ViewTable,
};
use flowy_database::{prelude::*, schema::view_table};
use std::sync::Arc;

pub struct ViewController {
    user: Arc<dyn WorkspaceUser>,
}

impl ViewController {
    pub fn new(user: Arc<dyn WorkspaceUser>) -> Self { Self { user } }

    pub async fn save_view(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let view_table = ViewTable::new(params);
        let conn = self.user.db_connection()?;
        let view: View = view_table.clone().into();

        let _ = diesel::insert_into(view_table::table)
            .values(view_table)
            .execute(&*conn)?;

        Ok(view)
    }
}
