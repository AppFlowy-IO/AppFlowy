use flowy_database::{
    query_dsl::*,
    schema::{user_table, user_table::dsl},
    DBConnection,
    ExpressionMethods,
};
use flowy_infra::kv::KVStore;
use lazy_static::lazy_static;
use std::sync::RwLock;

use crate::{
    entities::{SignInParams, SignUpParams, UserDetail, UserId},
    errors::UserError,
    services::user_session::{
        database::UserDB,
        register::{UserServer, *},
    },
    sql_tables::User,
};

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
    server: Box<dyn UserServer + Send + Sync>,
}

impl UserSession {
    pub fn new<R>(config: UserSessionConfig, register: R) -> Self
    where
        R: 'static + UserServer + Send + Sync,
    {
        let db = UserDB::new(&config.root_dir);
        Self {
            database: db,
            config,
            server: Box::new(register),
        }
    }

    pub async fn sign_in(&self, params: SignInParams) -> Result<User, UserError> {
        let user = self.server.sign_in(params)?;
        let _ = set_current_user_id(Some(user.id.clone()))?;
        self.save_user(user)
    }

    pub async fn sign_up(&self, params: SignUpParams) -> Result<User, UserError> {
        let user = self.server.sign_up(params)?;
        let _ = set_current_user_id(Some(user.id.clone()))?;
        self.save_user(user)
    }

    pub fn sign_out(&self) -> Result<(), UserError> {
        let _ = set_current_user_id(None)?;
        // TODO: close the db
        unimplemented!()
    }

    pub async fn get_user_status(&self, user_id: &str) -> Result<UserDetail, UserError> {
        let user_id = UserId::parse(user_id.to_owned()).map_err(|e| UserError::Auth(e))?;
        let conn = self.get_db_connection()?;

        let user = dsl::user_table
            .filter(user_table::id.eq(user_id.as_ref()))
            .first::<User>(&*conn)?;

        // TODO: getting user detail from remote
        Ok(UserDetail::from(user))
    }

    pub fn get_db_connection(&self) -> Result<DBConnection, UserError> {
        match get_current_user_id()? {
            None => Err(UserError::Auth("User is not login yet".to_owned())),
            Some(user_id) => self.database.get_connection(&user_id),
        }
    }
}

impl UserSession {
    fn save_user(&self, user: User) -> Result<User, UserError> {
        let conn = self.get_db_connection()?;
        let result = diesel::insert_into(user_table::table)
            .values(user.clone())
            .execute(&*conn)?;

        Ok(user)
    }
}
