use flowy_database::{
    query_dsl::*,
    schema::{user_table, user_table::dsl},
    DBConnection,
    ExpressionMethods,
    UserDatabaseConnection,
};
use flowy_infra::kv::KVStore;

use std::sync::{Arc, RwLock};

use crate::{
    entities::{SignInParams, SignUpParams, UpdateUserParams, UpdateUserRequest, UserDetail},
    errors::{ErrorBuilder, UserError, UserErrorCode},
    event::UserEvent::*,
    services::user_session::{database::UserDB, user_server::UserServer},
    sql_tables::{User, UserChangeset},
};
use flowy_dispatch::prelude::{EventDispatch, ModuleRequest, ToBytes};

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
    server: Arc<dyn UserServer + Send + Sync>,
    user_id: RwLock<Option<String>>,
}

impl UserSession {
    pub fn new<R>(config: UserSessionConfig, server: Arc<R>) -> Self
    where
        R: 'static + UserServer + Send + Sync,
    {
        let db = UserDB::new(&config.root_dir);
        Self {
            database: db,
            config,
            server,
            user_id: RwLock::new(None),
        }
    }

    pub fn get_db_connection(&self) -> Result<DBConnection, UserError> {
        let user_id = self.get_user_id()?;
        self.database.get_connection(&user_id)
    }

    pub fn sign_in(&self, params: SignInParams) -> Result<User, UserError> {
        let user = self.server.sign_in(params)?;
        let _ = self.set_user_id(Some(user.id.clone()))?;

        self.save_user(user)
    }

    pub fn sign_up(&self, params: SignUpParams) -> Result<User, UserError> {
        let user = self.server.sign_up(params)?;
        let _ = self.set_user_id(Some(user.id.clone()))?;
        self.save_user(user)
    }

    pub fn sign_out(&self) -> Result<(), UserError> {
        let user_id = self.get_user_id()?;
        let conn = self.get_db_connection()?;
        let _ = diesel::delete(dsl::user_table.filter(dsl::id.eq(&user_id))).execute(&*conn)?;

        match self.server.sign_out(&user_id) {
            Ok(_) => {},
            Err(_) => {},
        }
        let _ = self.database.close_user_db(&user_id)?;
        let _ = self.set_user_id(None)?;

        Ok(())
    }

    fn save_user(&self, user: User) -> Result<User, UserError> {
        let conn = self.get_db_connection()?;
        let _ = diesel::insert_into(user_table::table)
            .values(user.clone())
            .execute(&*conn)?;

        Ok(user)
    }

    pub fn update_user(&self, params: UpdateUserParams) -> Result<UserDetail, UserError> {
        let changeset = UserChangeset::new(params);
        let conn = self.get_db_connection()?;
        diesel_update_table!(user_table, changeset, conn);

        let user_detail = self.user_detail()?;
        Ok(user_detail)
    }

    pub fn user_detail(&self) -> Result<UserDetail, UserError> {
        let user_id = self.get_user_id()?;
        let conn = self.get_db_connection()?;

        let user = dsl::user_table
            .filter(user_table::id.eq(&user_id))
            .first::<User>(&*conn)?;

        match self.server.get_user_info(&user_id) {
            Ok(_user_detail) => {
                // TODO: post latest user_detail to upper layer
            },
            Err(_e) => {
                // log::debug!("Get user details failed. {:?}", e);
            },
        }

        Ok(UserDetail::from(user))
    }

    pub fn set_user_id(&self, user_id: Option<String>) -> Result<(), UserError> {
        log::trace!("Set user id: {:?}", user_id);
        KVStore::set_str(USER_ID_CACHE_KEY, user_id.clone().unwrap_or("".to_owned()));
        match self.user_id.write() {
            Ok(mut write_guard) => {
                *write_guard = user_id;
                Ok(())
            },
            Err(e) => Err(ErrorBuilder::new(UserErrorCode::WriteCurrentIdFailed)
                .error(e)
                .build()),
        }
    }

    pub fn get_user_id(&self) -> Result<String, UserError> {
        let read_guard = self.user_id.read().map_err(|e| {
            ErrorBuilder::new(UserErrorCode::ReadCurrentIdFailed)
                .error(e)
                .build()
        })?;

        let mut user_id = (*read_guard).clone();
        drop(read_guard);

        if user_id.is_none() {
            user_id = KVStore::get_str(USER_ID_CACHE_KEY);
            self.set_user_id(user_id.clone());
        }

        match user_id {
            None => Err(ErrorBuilder::new(UserErrorCode::UserNotLoginYet).build()),
            Some(user_id) => Ok(user_id),
        }
    }

    pub async fn set_current_workspace(&self, workspace_id: &str) -> Result<(), UserError> {
        let user_id = self.get_user_id()?;
        let payload: Vec<u8> = UpdateUserRequest::new(&user_id)
            .workspace(workspace_id)
            .into_bytes()
            .unwrap();

        let request = ModuleRequest::new(UpdateUser).payload(payload);
        let _user_detail = EventDispatch::async_send(request)
            .await
            .parse::<UserDetail, UserError>()
            .unwrap()
            .unwrap();
        Ok(())
    }
}

pub fn current_user_id() -> Result<String, UserError> {
    match KVStore::get_str(USER_ID_CACHE_KEY) {
        None => Err(ErrorBuilder::new(UserErrorCode::UserNotLoginYet).build()),
        Some(user_id) => Ok(user_id),
    }
}

impl UserDatabaseConnection for UserSession {
    fn get_connection(&self) -> Result<DBConnection, String> {
        self.get_db_connection().map_err(|e| format!("{:?}", e))
    }
}

const USER_ID_CACHE_KEY: &str = "user_id";
