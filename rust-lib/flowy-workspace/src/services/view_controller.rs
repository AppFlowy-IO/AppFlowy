use crate::{
    entities::view::{CreateViewParams, UpdateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    observable::{send_observable, WorkspaceObservable},
    sql_tables::view::{ViewTable, ViewTableChangeset, ViewTableSql},
};
use std::sync::Arc;

pub struct ViewController {
    sql: Arc<ViewTableSql>,
}

impl ViewController {
    pub fn new(database: Arc<dyn WorkspaceDatabase>) -> Self {
        let sql = Arc::new(ViewTableSql { database });
        Self { sql }
    }

    pub async fn create_view(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let view_table = ViewTable::new(params);
        let view: View = view_table.clone().into();
        let _ = self.sql.create_view(view_table)?;

        send_observable(&view.belong_to_id, WorkspaceObservable::AppAddView);
        Ok(view)
    }

    pub async fn read_view(&self, view_id: &str) -> Result<View, WorkspaceError> {
        let view_table = self.sql.read_view(view_id)?;
        let view: View = view_table.into();
        Ok(view)
    }

    pub async fn update_view(&self, params: UpdateViewParams) -> Result<(), WorkspaceError> {
        let changeset = ViewTableChangeset::new(params);
        let view_id = changeset.id.clone();
        let _ = self.sql.update_view(changeset)?;
        send_observable(&view_id, WorkspaceObservable::ViewUpdateDesc);

        Ok(())
    }
}
