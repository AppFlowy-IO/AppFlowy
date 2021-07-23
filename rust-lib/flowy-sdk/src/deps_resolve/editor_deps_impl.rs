use flowy_database::DBConnection;
use flowy_editor::{
    errors::{EditorError, EditorErrorCode, ErrorBuilder},
    module::EditorDatabase,
};
use flowy_user::prelude::UserSession;
use std::sync::Arc;

pub struct EditorDatabaseImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl EditorDatabase for EditorDatabaseImpl {
    fn db_connection(&self) -> Result<DBConnection, EditorError> {
        self.user_session.get_db_connection().map_err(|e| {
            ErrorBuilder::new(EditorErrorCode::EditorDBConnFailed)
                .error(e)
                .build()
        })
    }
}
