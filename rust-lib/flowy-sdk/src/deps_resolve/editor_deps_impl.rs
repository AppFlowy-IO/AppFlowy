use flowy_database::DBConnection;
use flowy_document::{
    errors::{DocError, ErrorBuilder, ErrorCode},
    module::{DocumentDatabase, DocumentUser},
};
use flowy_user::prelude::UserSession;
use std::{path::Path, sync::Arc};

pub struct EditorDatabaseImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl DocumentDatabase for EditorDatabaseImpl {
    fn db_connection(&self) -> Result<DBConnection, DocError> {
        self.user_session
            .db_conn()
            .map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())
    }
}

pub struct EditorUserImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl DocumentUser for EditorUserImpl {
    fn user_doc_dir(&self) -> Result<String, DocError> {
        let dir = self
            .user_session
            .user_dir()
            .map_err(|e| ErrorBuilder::new(ErrorCode::UserUnauthorized).error(e).build())?;

        let doc_dir = format!("{}/doc", dir);
        if !Path::new(&doc_dir).exists() {
            // TODO: Make sure to unwrap? 😁
            std::fs::create_dir_all(&doc_dir).unwrap();
        }
        Ok(doc_dir)
    }

    fn user_id(&self) -> Result<String, DocError> {
        self.user_session
            .user_id()
            .map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())
    }

    fn token(&self) -> Result<String, DocError> {
        self.user_session
            .token()
            .map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())
    }
}
