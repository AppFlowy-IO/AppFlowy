use crate::{
    entities::{SignInParams, SignUpParams, UpdateUserParams, UserProfile},
    errors::{ErrorCode, UserError},
    services::user::database::UserDB,
    sql_tables::{UserTable, UserTableChangeset},
};

use crate::{
    observable::*,
    services::server::{construct_user_server, Server},
};
use flowy_database::{
    query_dsl::*,
    schema::{user_table, user_table::dsl},
    DBConnection,
    ExpressionMethods,
    UserDatabaseConnection,
};
use flowy_infra::kv::KV;
use flowy_sqlite::ConnectionPool;
use flowy_ws::{connect::Retry, WsController, WsMessage, WsMessageHandler};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::{sync::Arc, time::Duration};

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

pub enum SessionStatus {
    Login { token: String },
    Expired { token: String },
}
pub type SessionStatusCallback = Arc<dyn Fn(SessionStatus) + Send + Sync>;

pub struct UserSession {
    database: UserDB,
    config: UserSessionConfig,
    #[allow(dead_code)]
    server: Server,
    session: RwLock<Option<Session>>,
    ws_controller: Arc<RwLock<WsController>>,
    status_callback: SessionStatusCallback,
}

impl UserSession {
    pub fn new(config: UserSessionConfig, status_callback: SessionStatusCallback) -> Self {
        let db = UserDB::new(&config.root_dir);
        let server = construct_user_server();
        let ws_controller = Arc::new(RwLock::new(WsController::new()));
        let user_session = Self {
            database: db,
            config,
            server,
            session: RwLock::new(None),
            ws_controller,
            status_callback,
        };
        user_session
    }

    pub fn db_connection(&self) -> Result<DBConnection, UserError> {
        let user_id = self.get_session()?.user_id;
        self.database.get_connection(&user_id)
    }

    // The caller will be not 'Sync' before of the return value,
    // PooledConnection<ConnectionManager> is not sync. You can use
    // db_connection_pool function to require the ConnectionPool that is 'Sync'.
    //
    // let pool = self.db_connection_pool()?;
    // let conn: PooledConnection<ConnectionManager> = pool.get()?;
    pub fn db_pool(&self) -> Result<Arc<ConnectionPool>, UserError> {
        let user_id = self.get_session()?.user_id;
        self.database.get_pool(&user_id)
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn sign_in(&self, params: SignInParams) -> Result<UserProfile, UserError> {
        if self.is_login(&params.email) {
            self.user_profile().await
        } else {
            let resp = self.server.sign_in(params).await?;
            let session = Session::new(&resp.user_id, &resp.token, &resp.email);
            let _ = self.set_session(Some(session))?;
            let user_table = self.save_user(resp.into()).await?;
            let user_profile = UserProfile::from(user_table);
            (self.status_callback)(SessionStatus::Login {
                token: user_profile.token.clone(),
            });
            Ok(user_profile)
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn sign_up(&self, params: SignUpParams) -> Result<UserProfile, UserError> {
        if self.is_login(&params.email) {
            self.user_profile().await
        } else {
            let resp = self.server.sign_up(params).await?;
            let session = Session::new(&resp.user_id, &resp.token, &resp.email);
            let _ = self.set_session(Some(session))?;
            let user_table = self.save_user(resp.into()).await?;
            let user_profile = UserProfile::from(user_table);
            (self.status_callback)(SessionStatus::Login {
                token: user_profile.token.clone(),
            });
            Ok(user_profile)
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn sign_out(&self) -> Result<(), UserError> {
        let session = self.get_session()?;
        let _ = diesel::delete(dsl::user_table.filter(dsl::id.eq(&session.user_id))).execute(&*(self.db_connection()?))?;
        let _ = self.database.close_user_db(&session.user_id)?;
        let _ = self.set_session(None)?;
        (self.status_callback)(SessionStatus::Expired {
            token: session.token.clone(),
        });
        let _ = self.sign_out_on_server(&session.token).await?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn update_user(&self, params: UpdateUserParams) -> Result<(), UserError> {
        let session = self.get_session()?;
        let changeset = UserTableChangeset::new(params.clone());
        diesel_update_table!(user_table, changeset, &*self.db_connection()?);

        let _ = self.update_user_on_server(&session.token, params).await?;
        Ok(())
    }

    pub async fn init_user(&self) -> Result<UserProfile, UserError> {
        let (user_id, token) = self.get_session()?.into_part();

        let user = dsl::user_table
            .filter(user_table::id.eq(&user_id))
            .first::<UserTable>(&*(self.db_connection()?))?;

        let _ = self.read_user_profile_on_server(&token)?;
        let _ = self.start_ws_connection(&token)?;

        Ok(UserProfile::from(user))
    }

    pub async fn user_profile(&self) -> Result<UserProfile, UserError> {
        let (user_id, token) = self.get_session()?.into_part();
        let user = dsl::user_table
            .filter(user_table::id.eq(&user_id))
            .first::<UserTable>(&*(self.db_connection()?))?;

        let _ = self.read_user_profile_on_server(&token)?;
        Ok(UserProfile::from(user))
    }

    pub fn user_dir(&self) -> Result<String, UserError> {
        let session = self.get_session()?;
        Ok(format!("{}/{}", self.config.root_dir, session.user_id))
    }

    pub fn user_id(&self) -> Result<String, UserError> { Ok(self.get_session()?.user_id) }

    pub fn token(&self) -> Result<String, UserError> { Ok(self.get_session()?.token) }

    pub fn add_ws_msg_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), UserError> {
        let _ = self.ws_controller.write().add_handler(handler)?;
        Ok(())
    }

    // pub fn send_ws_msg<T: Into<WsMessage>>(&self, msg: T) -> Result<(),
    // UserError> {     match self.ws_controller.try_read_for(Duration::
    // from_millis(300)) {         None =>
    // Err(UserError::internal().context("Send ws message timeout")),
    //         Some(guard) => {
    //             let _ = guard.send_msg(msg)?;
    //             Ok(())
    //         },
    //     }
    // }
}

impl UserSession {
    fn read_user_profile_on_server(&self, token: &str) -> Result<(), UserError> {
        let server = self.server.clone();
        let token = token.to_owned();
        tokio::spawn(async move {
            match server.get_user(&token).await {
                Ok(profile) => {
                    notify(&token, UserObservable::UserProfileUpdated).payload(profile).send();
                },
                Err(e) => {
                    notify(&token, UserObservable::UserProfileUpdated).error(e).send();
                },
            }
        });
        Ok(())
    }

    async fn update_user_on_server(&self, token: &str, params: UpdateUserParams) -> Result<(), UserError> {
        let server = self.server.clone();
        let token = token.to_owned();
        let _ = tokio::spawn(async move {
            match server.update_user(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("update user profile failed: {:?}", e);
                },
            }
        })
        .await;
        Ok(())
    }

    async fn sign_out_on_server(&self, token: &str) -> Result<(), UserError> {
        let server = self.server.clone();
        let token = token.to_owned();
        let _ = tokio::spawn(async move {
            match server.sign_out(&token).await {
                Ok(_) => {},
                Err(e) => log::error!("Sign out failed: {:?}", e),
            }
        })
        .await;
        Ok(())
    }

    async fn save_user(&self, user: UserTable) -> Result<UserTable, UserError> {
        let conn = self.db_connection()?;
        let _ = diesel::insert_into(user_table::table).values(user.clone()).execute(&*conn)?;
        Ok(user)
    }

    fn set_session(&self, session: Option<Session>) -> Result<(), UserError> {
        log::debug!("Set user session: {:?}", session);
        match &session {
            None => KV::remove(SESSION_CACHE_KEY).map_err(|e| UserError::new(ErrorCode::InternalError, &e))?,
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
            None => Err(UserError::unauthorized()),
            Some(session) => Ok(session),
        }
    }

    fn is_login(&self, email: &str) -> bool {
        match self.get_session() {
            Ok(session) => session.email == email,
            Err(_) => false,
        }
    }

    fn start_ws_connection(&self, token: &str) -> Result<(), UserError> {
        let addr = format!("{}/{}", flowy_net::config::WS_ADDR.as_str(), token);
        let ws_controller = self.ws_controller.clone();
        let retry = Retry::new(&addr, move |addr| {
            ws_controller.write().connect(addr.to_owned());
        });

        let _ = self.ws_controller.write().connect_with_retry(addr, retry);
        Ok(())
    }
}

pub async fn update_user(_server: Server, pool: Arc<ConnectionPool>, params: UpdateUserParams) -> Result<(), UserError> {
    let changeset = UserTableChangeset::new(params);
    let conn = pool.get()?;
    diesel_update_table!(user_table, changeset, &*conn);
    Ok(())
}

impl UserDatabaseConnection for UserSession {
    fn get_connection(&self) -> Result<DBConnection, String> { self.db_connection().map_err(|e| format!("{:?}", e)) }
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

    pub fn into_part(self) -> (String, String) { (self.user_id, self.token) }
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
