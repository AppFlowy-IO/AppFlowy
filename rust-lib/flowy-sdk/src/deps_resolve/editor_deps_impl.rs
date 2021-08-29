use flowy_database::DBConnection;
use flowy_document::{
    errors::{DocError, DocErrorCode, ErrorBuilder},
    module::{DocumentDatabase, DocumentUser},
};
use flowy_user::prelude::UserSession;
use std::{path::Path, sync::Arc};

pub struct EditorDatabaseImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl DocumentDatabase for EditorDatabaseImpl {
    fn db_connection(&self) -> Result<DBConnection, DocError> {
        self.user_session.get_db_connection().map_err(|e| {
            ErrorBuilder::new(DocErrorCode::EditorDBConnFailed)
                .error(e)
                .build()
        })
    }
}

pub struct EditorUserImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl DocumentUser for EditorUserImpl {
    fn user_doc_dir(&self) -> Result<String, DocError> {
        let dir = self.user_session.user_dir().map_err(|e| {
            ErrorBuilder::new(DocErrorCode::EditorUserNotLoginYet)
                .error(e)
                .build()
        })?;

        let doc_dir = format!("{}/doc", dir);
        if !Path::new(&doc_dir).exists() {
            // TODO: Make sure to unwrap? 😁
            std::fs::create_dir_all(&doc_dir).unwrap();
        }
        Ok(doc_dir)
    }
}
