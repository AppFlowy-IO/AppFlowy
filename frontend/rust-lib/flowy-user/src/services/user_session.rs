use crate::entities::{
    SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams, UserProfilePB, UserSettingPB,
};
use crate::{
    dart_notification::*,
    errors::{ErrorCode, FlowyError},
    event_map::UserCloudService,
    services::{
        database::{UserDB, UserTable, UserTableChangeset},
        notifier::UserNotifier,
    },
};
use flowy_database::ConnectionPool;
use flowy_database::{
    kv::KV,
    query_dsl::*,
    schema::{user_table, user_table::dsl},
    DBConnection, ExpressionMethods, UserDatabaseConnection,
};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::mpsc;

pub struct UserSessionConfig {
    root_dir: String,
    session_cache_key: String,
}

impl UserSessionConfig {
    pub fn new(root_dir: &str, session_cache_key: &str) -> Self {
        Self {
            root_dir: root_dir.to_owned(),
            session_cache_key: session_cache_key.to_owned(),
        }
    }
}

pub struct UserSession {
    database: UserDB,
    config: UserSessionConfig,
    cloud_service: Arc<dyn UserCloudService>,
    session: RwLock<Option<Session>>,
    pub notifier: UserNotifier,
}

impl UserSession {
    pub fn new(config: UserSessionConfig, cloud_service: Arc<dyn UserCloudService>) -> Self {
        let db = UserDB::new(&config.root_dir);
        let notifier = UserNotifier::new();
        Self {
            database: db,
            config,
            cloud_service,
            session: RwLock::new(None),
            notifier,
        }
    }

    pub fn init(&self) {
        if let Ok(session) = self.get_session() {
            self.notifier.notify_login(&session.token, &session.user_id);
        }
    }

    pub fn db_connection(&self) -> Result<DBConnection, FlowyError> {
        let user_id = self.get_session()?.user_id;
        self.database.get_connection(&user_id)
    }

    // The caller will be not 'Sync' before of the return value,
    // PooledConnection<ConnectionManager> is not sync. You can use
    // db_connection_pool function to require the ConnectionPool that is 'Sync'.
    //
    // let pool = self.db_connection_pool()?;
    // let conn: PooledConnection<ConnectionManager> = pool.get()?;
    pub fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
        let user_id = self.get_session()?.user_id;
        self.database.get_pool(&user_id)
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn sign_in(&self, params: SignInParams) -> Result<UserProfilePB, FlowyError> {
        if self.is_user_login(&params.email) {
            self.get_user_profile().await
        } else {
            let resp = self.cloud_service.sign_in(params).await?;
            let session: Session = resp.clone().into();
            let _ = self.set_session(Some(session))?;
            let user_table = self.save_user(resp.into()).await?;
            let user_profile: UserProfilePB = user_table.into();
            self.notifier.notify_login(&user_profile.token, &user_profile.id);
            Ok(user_profile)
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn sign_up(&self, params: SignUpParams) -> Result<UserProfilePB, FlowyError> {
        if self.is_user_login(&params.email) {
            self.get_user_profile().await
        } else {
            let resp = self.cloud_service.sign_up(params).await?;
            let session: Session = resp.clone().into();
            let _ = self.set_session(Some(session))?;
            let user_table = self.save_user(resp.into()).await?;
            let user_profile: UserProfilePB = user_table.into();
            let (ret, mut tx) = mpsc::channel(1);
            self.notifier.notify_sign_up(ret, &user_profile);

            let _ = tx.recv().await;
            Ok(user_profile)
        }
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn sign_out(&self) -> Result<(), FlowyError> {
        let session = self.get_session()?;
        let _ =
            diesel::delete(dsl::user_table.filter(dsl::id.eq(&session.user_id))).execute(&*(self.db_connection()?))?;
        let _ = self.database.close_user_db(&session.user_id)?;
        let _ = self.set_session(None)?;
        self.notifier.notify_logout(&session.token, &session.user_id);
        let _ = self.sign_out_on_server(&session.token).await?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self))]
    pub async fn update_user_profile(&self, params: UpdateUserProfileParams) -> Result<(), FlowyError> {
        let session = self.get_session()?;
        let changeset = UserTableChangeset::new(params.clone());
        diesel_update_table!(user_table, changeset, &*self.db_connection()?);

        let user_profile = self.get_user_profile().await?;
        dart_notify(&session.token, UserNotification::UserProfileUpdated)
            .payload(user_profile)
            .send();
        let _ = self.update_user_on_server(&session.token, params).await?;
        Ok(())
    }

    pub async fn init_user(&self) -> Result<(), FlowyError> {
        Ok(())
    }

    pub async fn check_user(&self) -> Result<UserProfilePB, FlowyError> {
        let (user_id, token) = self.get_session()?.into_part();

        let user = dsl::user_table
            .filter(user_table::id.eq(&user_id))
            .first::<UserTable>(&*(self.db_connection()?))?;

        let _ = self.read_user_profile_on_server(&token)?;
        Ok(user.into())
    }

    pub async fn get_user_profile(&self) -> Result<UserProfilePB, FlowyError> {
        let (user_id, token) = self.get_session()?.into_part();
        let user = dsl::user_table
            .filter(user_table::id.eq(&user_id))
            .first::<UserTable>(&*(self.db_connection()?))?;

        let _ = self.read_user_profile_on_server(&token)?;
        Ok(user.into())
    }

    pub fn user_dir(&self) -> Result<String, FlowyError> {
        let session = self.get_session()?;
        Ok(format!("{}/{}", self.config.root_dir, session.user_id))
    }

    pub fn user_setting(&self) -> Result<UserSettingPB, FlowyError> {
        let user_setting = UserSettingPB {
            user_folder: self.user_dir()?,
        };
        Ok(user_setting)
    }

    pub fn user_id(&self) -> Result<String, FlowyError> {
        Ok(self.get_session()?.user_id)
    }

    pub fn user_name(&self) -> Result<String, FlowyError> {
        Ok(self.get_session()?.name)
    }

    pub fn token(&self) -> Result<String, FlowyError> {
        Ok(self.get_session()?.token)
    }
}

impl UserSession {
    fn read_user_profile_on_server(&self, _token: &str) -> Result<(), FlowyError> {
        // let server = self.cloud_service.clone();
        // let token = token.to_owned();
        // tokio::spawn(async move {
        //     match server.get_user(&token).await {
        //         Ok(profile) => {
        //             dart_notify(&token, UserNotification::UserProfileUpdated)
        //                 .payload(profile)
        //                 .send();
        //         }
        //         Err(e) => {
        //             dart_notify(&token, UserNotification::UserProfileUpdated)
        //                 .error(e)
        //                 .send();
        //         }
        //     }
        // });
        Ok(())
    }

    async fn update_user_on_server(&self, token: &str, params: UpdateUserProfileParams) -> Result<(), FlowyError> {
        let server = self.cloud_service.clone();
        let token = token.to_owned();
        let _ = tokio::spawn(async move {
            match server.update_user(&token, params).await {
                Ok(_) => {}
                Err(e) => {
                    // TODO: retry?
                    log::error!("update user profile failed: {:?}", e);
                }
            }
        })
        .await;
        Ok(())
    }

    async fn sign_out_on_server(&self, token: &str) -> Result<(), FlowyError> {
        let server = self.cloud_service.clone();
        let token = token.to_owned();
        let _ = tokio::spawn(async move {
            match server.sign_out(&token).await {
                Ok(_) => {}
                Err(e) => log::error!("Sign out failed: {:?}", e),
            }
        })
        .await;
        Ok(())
    }

    async fn save_user(&self, user: UserTable) -> Result<UserTable, FlowyError> {
        let conn = self.db_connection()?;
        let _ = diesel::insert_into(user_table::table)
            .values(user.clone())
            .execute(&*conn)?;
        Ok(user)
    }

    fn set_session(&self, session: Option<Session>) -> Result<(), FlowyError> {
        tracing::debug!("Set user session: {:?}", session);
        match &session {
            None => KV::remove(&self.config.session_cache_key).map_err(|e| FlowyError::new(ErrorCode::Internal, &e))?,
            Some(session) => KV::set_str(&self.config.session_cache_key, session.clone().into()),
        }
        *self.session.write() = session;
        Ok(())
    }

    fn get_session(&self) -> Result<Session, FlowyError> {
        let mut session = { (*self.session.read()).clone() };
        if session.is_none() {
            match KV::get_str(&self.config.session_cache_key) {
                None => {}
                Some(s) => {
                    session = Some(Session::from(s));
                    let _ = self.set_session(session.clone())?;
                }
            }
        }

        match session {
            None => Err(FlowyError::unauthorized()),
            Some(session) => Ok(session),
        }
    }

    fn is_user_login(&self, email: &str) -> bool {
        match self.get_session() {
            Ok(session) => session.email == email,
            Err(_) => false,
        }
    }
}

pub async fn update_user(
    _cloud_service: Arc<dyn UserCloudService>,
    pool: Arc<ConnectionPool>,
    params: UpdateUserProfileParams,
) -> Result<(), FlowyError> {
    let changeset = UserTableChangeset::new(params);
    let conn = pool.get()?;
    diesel_update_table!(user_table, changeset, &*conn);
    Ok(())
}

impl UserDatabaseConnection for UserSession {
    fn get_connection(&self) -> Result<DBConnection, String> {
        self.db_connection().map_err(|e| format!("{:?}", e))
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
struct Session {
    user_id: String,
    token: String,
    email: String,
    #[serde(default)]
    name: String,
}

impl std::convert::From<SignInResponse> for Session {
    fn from(resp: SignInResponse) -> Self {
        Session {
            user_id: resp.user_id,
            token: resp.token,
            email: resp.email,
            name: resp.name,
        }
    }
}

impl std::convert::From<SignUpResponse> for Session {
    fn from(resp: SignUpResponse) -> Self {
        Session {
            user_id: resp.user_id,
            token: resp.token,
            email: resp.email,
            name: resp.name,
        }
    }
}

impl Session {
    pub fn into_part(self) -> (String, String) {
        (self.user_id, self.token)
    }
}

impl std::convert::From<String> for Session {
    fn from(s: String) -> Self {
        match serde_json::from_str(&s) {
            Ok(s) => s,
            Err(e) => {
                log::error!("Deserialize string to Session failed: {:?}", e);
                Session::default()
            }
        }
    }
}
impl std::convert::From<Session> for String {
    fn from(session: Session) -> Self {
        match serde_json::to_string(&session) {
            Ok(s) => s,
            Err(e) => {
                log::error!("Serialize session to string failed: {:?}", e);
                "".to_string()
            }
        }
    }
}
