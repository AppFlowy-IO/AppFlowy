use crate::{
    entities::view::{CreateViewParams, View},
    errors::WorkspaceError,
    module::WorkspaceDatabase,
    observable::{send_observable, WorkspaceObservable},
    sql_tables::view::{ViewTable, ViewTableSql},
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

    pub async fn save_view(&self, params: CreateViewParams) -> Result<View, WorkspaceError> {
        let view_table = ViewTable::new(params);
        let view: View = view_table.clone().into();
        let _ = self.sql.write_view_table(view_table)?;

        send_observable(&view.id, WorkspaceObservable::AppAddView);
        Ok(view)
    }
}
