use crate::{
    domain::{tables::User, SignUpParams},
    errors::UserError,
    services::{database::UserDB, register::UserRegister},
};
use ::diesel::query_dsl::*;
use flowy_database::schema::user_table;
use flowy_sqlite::DBConnection;
use lazy_static::lazy_static;
use std::sync::RwLock;

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
    register: Box<dyn UserRegister + Send + Sync>,
}

impl UserSession {
    pub fn new<R>(config: UserSessionConfig, register: R) -> Self
    where
        R: 'static + UserRegister + Send + Sync,
    {
        let db = UserDB::new(&config.root_dir);
        Self {
            database: db,
            config,
            register: Box::new(register),
        }
    }

    pub fn get_db_connection(&self) -> Result<DBConnection, UserError> {
        match get_current_user_id()? {
            None => Err(UserError::Auth("User is not login yet".to_owned())),
            Some(user_id) => self.database.get_connection(&user_id),
        }
    }

    pub fn sign_up(&self, params: SignUpParams) -> Result<User, UserError> {
        let user = self.register.register_user(params)?;
        set_current_user_id(Some(user.id.clone()));

        let conn = self.get_db_connection()?;
        let _ = diesel::insert_into(user_table::table)
            .values(user.clone())
            .execute(&*conn)?;

        Ok(user)
    }

    pub fn sign_out(&self) -> Result<(), UserError> {
        set_current_user_id(None);
        // TODO: close the db
        unimplemented!()
    }
}

lazy_static! {
    pub static ref CURRENT_USER_ID: RwLock<Option<String>> = RwLock::new(None);
}
fn get_current_user_id() -> Result<Option<String>, UserError> {
    let current_user_id = CURRENT_USER_ID
        .read()
        .map_err(|e| UserError::Auth(format!("Read current user id failed. {:?}", e)))?;

    Ok((*current_user_id).clone())
}

pub fn set_current_user_id(user_id: Option<String>) -> Result<(), UserError> {
    let mut current_user_id = CURRENT_USER_ID
        .write()
        .map_err(|e| UserError::Auth(format!("Write current user id failed. {:?}", e)))?;
    *current_user_id = user_id;
    Ok(())
}
