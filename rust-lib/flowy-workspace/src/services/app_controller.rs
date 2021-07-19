use crate::{
    entities::app::{App, CreateAppParams, *},
    errors::*,
    module::WorkspaceUser,
    sql_tables::app::*,
};
use flowy_database::{prelude::*, schema::app_table};
use std::sync::Arc;

pub struct AppController {
    user: Arc<dyn WorkspaceUser>,
}

impl AppController {
    pub fn new(user: Arc<dyn WorkspaceUser>) -> Self { Self { user } }

    pub fn save_app(&self, params: CreateAppParams) -> Result<App, WorkspaceError> {
        let app_table = AppTable::new(params);
        let conn = self.user.db_connection()?;

        let app: App = app_table.clone().into();
        let _ = diesel::insert_into(app_table::table)
            .values(app_table)
            .execute(&*conn)?;
        Ok(app)
    }

    pub fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppTableChangeset::new(params);
        let conn = self.user.db_connection()?;
        diesel_update_table!(app_table, changeset, conn);
        Ok(())
    }
}
