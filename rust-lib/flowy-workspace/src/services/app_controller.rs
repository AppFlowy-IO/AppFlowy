use crate::{
    entities::app::{AppDetail, CreateAppParams, *},
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

    pub fn save_app(&self, params: CreateAppParams) -> Result<AppDetail, WorkspaceError> {
        let app = App::new(params);
        let conn = self.user.db_connection()?;

        let detail: AppDetail = app.clone().into();
        let _ = diesel::insert_into(app_table::table)
            .values(app)
            .execute(&*conn)?;
        Ok(detail)
    }

    pub fn update_app(&self, params: UpdateAppParams) -> Result<(), WorkspaceError> {
        let changeset = AppChangeset::new(params);
        let conn = self.user.db_connection()?;
        diesel_update_table!(app_table, changeset, conn);
        Ok(())
    }
}
