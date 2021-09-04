use crate::{
    entities::{SignInParams, SignUpParams, UpdateUserParams, UserDetail},
    errors::{ErrorBuilder, ErrorCode, UserError},
    services::user::{construct_user_server, database::UserDB},
    sql_tables::{UserTable, UserTableChangeset},
};

use flowy_database::{
    query_dsl::*,
    schema::{user_table, user_table::dsl},
    DBConnection,
    ExpressionMethods,
    UserDatabaseConnection,
};

use crate::services::server::Server;
use flowy_infra::kv::KV;
use flowy_sqlite::ConnectionPool;
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};

use std::sync::Arc;

pub struct UserSessionConfig {
    root_dir: String,
}

impl UserSessionConfig {
    pub fn new(root_dir: &str) -> Self {
        Self {
            root_dir: root_dir.to_owned(),
        }
    }
}

pub struct UserSession {
    database: UserDB,
    config: UserSessionConfig,
    #[allow(dead_code)]
    server: Server,
    session: RwLock<Option<Session>>,
}

impl UserSession {
    pub fn new(config: UserSessionConfig) -> Self {
        let db = UserDB::new(&config.root_dir);
        let server = construct_user_server();
        Self {
            database: db,
            config,
            server,
            session: RwLock::new(None),
        }
    }

    pub fn get_db_connection(&self) -> Result<DBConnection, UserError> {
        let user_id = self.get_session()?.user_id;
        self.database.get_connection(&user_id)
    }

    // The caller will be not 'Sync' before of the return value,
    // PooledConnection<ConnectionManager> is not sync. You can use
    // db_connection_pool function to require the ConnectionPool that is 'Sync'.
    //
    // let pool = self.db_connection_pool()?;
    // let conn: PooledConnection<ConnectionManager> = pool.get()?;
    pub fn db_connection_pool(&self) -> Result<Arc<ConnectionPool>, UserError> {
        let user_id = self.get_session()?.user_id;
        self.database.get_pool(&user_id)
    }

    pub async fn sign_in(&self, params: SignInParams) -> Result<UserDetail, UserError> {
        if self.is_login(&params.email) {
            self.user_detail().await
        } else {
            let resp = self.server.sign_in(params).await?;
            let session = Session::new(&resp.uid, &resp.token, &resp.email);
            let _ = self.set_session(Some(session))?;
            let user_table = self.save_user(resp.into()).await?;
            let user_detail = UserDetail::from(user_table);
            Ok(user_detail)
        }
    }

    pub async fn sign_up(&self, params: SignUpParams) -> Result<UserDetail, UserError> {
        if self.is_login(&params.email) {
            self.user_detail().await
        } else {
            let resp = self.server.sign_up(params).await?;
            let session = Session::new(&resp.user_id, &resp.token, &resp.email);
            let _ = self.set_session(Some(session))?;
            let user_table = self.save_user(resp.into()).await?;
            let user_detail = UserDetail::from(user_table);
            Ok(user_detail)
        }
    }

    pub async fn sign_out(&self) -> Result<(), UserError> {
        let session = self.get_session()?;
        match self.server.sign_out(&session.token).await {
            Ok(_) => {},
            Err(e) => log::error!("Sign out failed: {:?}", e),
        }

        let conn = self.get_db_connection()?;
        let _ = diesel::delete(dsl::user_table.filter(dsl::id.eq(&session.user_id))).execute(&*conn)?;
        let _ = self.server.sign_out(&session.token);
        let _ = self.database.close_user_db(&session.user_id)?;
        let _ = self.set_session(None)?;

        Ok(())
    }

    pub async fn update_user(&self, params: UpdateUserParams) -> Result<(), UserError> {
        let session = self.get_session()?;
        match self.server.update_user(&session.token, params.clone()).await {
            Ok(_) => {},
            Err(e) => {
                // TODO: retry?
                log::error!("update user profile failed: {:?}", e);
            },
        }

        let changeset = UserTableChangeset::new(params);
        let conn = self.get_db_connection()?;
        diesel_update_table!(user_table, changeset, conn);
        Ok(())
    }

    pub async fn user_detail(&self) -> Result<UserDetail, UserError> {
        let session = self.get_session()?;
        let token = session.token;
        let server = self.server.clone();
        tokio::spawn(async move {
            match server.get_user_detail(&token).await {
                Ok(user_detail) => {
                    //
                    log::info!("{:?}", user_detail);
                },
                Err(e) => {
                    //
                    log::info!("{:?}", e);
                },
            }
        })
        .await;

        let user = dsl::user_table
            .filter(user_table::id.eq(&session.user_id))
            .first::<UserTable>(&*(self.get_db_connection()?))?;

        Ok(UserDetail::from(user))
    }

    pub fn user_dir(&self) -> Result<String, UserError> {
        let session = self.get_session()?;
        Ok(format!("{}/{}", self.config.root_dir, session.user_id))
    }

    pub fn user_id(&self) -> Result<String, UserError> { Ok(self.get_session()?.user_id) }

    pub fn token(&self) -> Result<String, UserError> { Ok(self.get_session()?.token) }
}

impl UserSession {
    async fn save_user(&self, user: UserTable) -> Result<UserTable, UserError> {
        let conn = self.get_db_connection()?;
        let _ = diesel::insert_into(user_table::table).values(user.clone()).execute(&*conn)?;

        Ok(user)
    }

    fn set_session(&self, session: Option<Session>) -> Result<(), UserError> {
        log::debug!("Update user session: {:?}", session);
        match &session {
            None => KV::remove(SESSION_CACHE_KEY).map_err(|e| UserError::new(ErrorCode::SqlInternalError, &e))?,
            Some(session) => KV::set_str(SESSION_CACHE_KEY, session.clone().into()),
        }
        *self.session.write() = session;
        Ok(())
    }

    fn get_session(&self) -> Result<Session, UserError> {
        let mut session = { (*self.session.read()).clone() };
        if session.is_none() {
            match KV::get_str(SESSION_CACHE_KEY) {
                None => {},
                Some(s) => {
                    session = Some(Session::from(s));
                    let _ = self.set_session(session.clone())?;
                },
            }
        }

        match session {
            None => Err(ErrorBuilder::new(ErrorCode::UserNotLoginYet).build()),
            Some(session) => Ok(session),
        }
    }

    fn is_login(&self, email: &str) -> bool {
        match self.get_session() {
            Ok(session) => session.email == email,
            Err(_) => false,
        }
    }
}

pub async fn update_user(_server: Server, pool: Arc<ConnectionPool>, params: UpdateUserParams) -> Result<(), UserError> {
    let changeset = UserTableChangeset::new(params);
    let conn = pool.get()?;
    diesel_update_table!(user_table, changeset, conn);
    Ok(())
}

impl UserDatabaseConnection for UserSession {
    fn get_connection(&self) -> Result<DBConnection, String> { self.get_db_connection().map_err(|e| format!("{:?}", e)) }
}

const SESSION_CACHE_KEY: &str = "session_cache_key";

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
struct Session {
    user_id: String,
    token: String,
    email: String,
}

impl Session {
    pub fn new(user_id: &str, token: &str, email: &str) -> Self {
        Self {
            user_id: user_id.to_owned(),
            token: token.to_owned(),
            email: email.to_owned(),
        }
    }
}

impl std::convert::From<String> for Session {
    fn from(s: String) -> Self {
        match serde_json::from_str(&s) {
            Ok(s) => s,
            Err(e) => {
                log::error!("Deserialize string to Session failed: {:?}", e);
                Session::default()
            },
        }
    }
}

impl std::convert::Into<String> for Session {
    fn into(self) -> String {
        match serde_json::to_string(&self) {
            Ok(s) => s,
            Err(e) => {
                log::error!("Serialize session to string failed: {:?}", e);
                "".to_string()
            },
        }
    }
}
