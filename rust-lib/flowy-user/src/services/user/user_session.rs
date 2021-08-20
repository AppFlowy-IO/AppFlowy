use crate::{
    entities::{SignInParams, SignUpParams, UpdateUserParams, UpdateUserRequest, UserDetail},
    errors::{ErrorBuilder, UserErrCode, UserError},
    event::UserEvent::*,
    services::{
        user::{construct_server, database::UserDB, UserServer},
        workspace::WorkspaceAction,
    },
    sql_tables::{UserTable, UserTableChangeset},
};
use flowy_database::{
    query_dsl::*,
    schema::{user_table, user_table::dsl},
    DBConnection,
    ExpressionMethods,
    UserDatabaseConnection,
};
use flowy_dispatch::prelude::{EventDispatch, ModuleRequest, ToBytes};
use flowy_infra::kv::KVStore;
use std::sync::{Arc, RwLock};

const DEFAULT_WORKSPACE_NAME: &'static str = "My workspace";
const DEFAULT_WORKSPACE_DESC: &'static str = "This is your first workspace";
const DEFAULT_WORKSPACE: &'static str = "Default_Workspace";

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
    workspace: Arc<dyn WorkspaceAction + Send + Sync>,
    server: Arc<dyn UserServer + Send + Sync>,
    user_id: RwLock<Option<String>>,
}

impl UserSession {
    pub fn new<R>(config: UserSessionConfig, workspace: Arc<R>) -> Self
    where
        R: 'static + WorkspaceAction + Send + Sync,
    {
        let db = UserDB::new(&config.root_dir);
        let server = construct_server();
        Self {
            database: db,
            config,
            workspace,
            server,
            user_id: RwLock::new(None),
        }
    }

    pub fn get_db_connection(&self) -> Result<DBConnection, UserError> {
        let user_id = self.get_user_id()?;
        self.database.get_connection(&user_id)
    }

    pub async fn sign_in(&self, params: SignInParams) -> Result<UserTable, UserError> {
        let resp = self.server.sign_in(params).await?;
        let _ = self.set_user_id(Some(resp.uid.clone()))?;
        let user_table = self.save_user(resp.into()).await?;

        Ok(user_table)
    }

    pub async fn sign_up(&self, params: SignUpParams) -> Result<UserTable, UserError> {
        let resp = self.server.sign_up(params).await?;
        let _ = self.set_user_id(Some(resp.uid.clone()))?;
        let user_table = self.save_user(resp.into()).await?;

        Ok(user_table)
    }

    pub fn sign_out(&self) -> Result<(), UserError> {
        let user_id = self.get_user_id()?;
        let conn = self.get_db_connection()?;
        let _ = diesel::delete(dsl::user_table.filter(dsl::id.eq(&user_id))).execute(&*conn)?;
        let _ = self.server.sign_out(&user_id);
        let _ = self.database.close_user_db(&user_id)?;
        let _ = self.set_user_id(None)?;

        Ok(())
    }

    async fn save_user(&self, mut user: UserTable) -> Result<UserTable, UserError> {
        if user.workspace.is_empty() {
            log::info!("Try to create user default workspace");
            let workspace_id = self.create_default_workspace_if_need(&user.id).await?;
            user.workspace = workspace_id;
        }

        let conn = self.get_db_connection()?;
        let _ = diesel::insert_into(user_table::table)
            .values(user.clone())
            .execute(&*conn)?;

        Ok(user)
    }

    pub fn update_user(&self, params: UpdateUserParams) -> Result<UserDetail, UserError> {
        let changeset = UserTableChangeset::new(params);
        let conn = self.get_db_connection()?;
        diesel_update_table!(user_table, changeset, conn);
        let user_detail = self.user_detail()?;
        Ok(user_detail)
    }

    pub fn user_detail(&self) -> Result<UserDetail, UserError> {
        let user_id = self.get_user_id()?;
        let user = dsl::user_table
            .filter(user_table::id.eq(&user_id))
            .first::<UserTable>(&*(self.get_db_connection()?))?;

        let _ = self.server.get_user_info(&user_id);

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
            Err(e) => Err(ErrorBuilder::new(UserErrCode::WriteCurrentIdFailed)
                .error(e)
                .build()),
        }
    }

    pub fn get_user_dir(&self) -> Result<String, UserError> {
        let user_id = self.get_user_id()?;
        Ok(format!("{}/{}", self.config.root_dir, user_id))
    }

    pub fn get_user_id(&self) -> Result<String, UserError> {
        let mut user_id = {
            let read_guard = self.user_id.read().map_err(|e| {
                ErrorBuilder::new(UserErrCode::ReadCurrentIdFailed)
                    .error(e)
                    .build()
            })?;

            (*read_guard).clone()
        };

        if user_id.is_none() {
            user_id = KVStore::get_str(USER_ID_CACHE_KEY);
            let _ = self.set_user_id(user_id.clone())?;
        }

        match user_id {
            None => Err(ErrorBuilder::new(UserErrCode::UserNotLoginYet).build()),
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
        let _ = EventDispatch::async_send(request)
            .await
            .parse::<UserDetail, UserError>()
            .unwrap()?;
        Ok(())
    }

    async fn create_default_workspace_if_need(&self, user_id: &str) -> Result<String, UserError> {
        let key = format!("{}{}", user_id, DEFAULT_WORKSPACE);
        if KVStore::get_bool(&key).unwrap_or(false) {
            return Err(ErrorBuilder::new(UserErrCode::DefaultWorkspaceAlreadyExist).build());
        }
        KVStore::set_bool(&key, true);
        log::debug!("Create user:{} default workspace", user_id);
        let workspace_id = self
            .workspace
            .create_workspace(DEFAULT_WORKSPACE_NAME, DEFAULT_WORKSPACE_DESC, user_id)
            .await?;
        Ok(workspace_id)
    }
}

pub fn current_user_id() -> Result<String, UserError> {
    match KVStore::get_str(USER_ID_CACHE_KEY) {
        None => Err(ErrorBuilder::new(UserErrCode::UserNotLoginYet).build()),
        Some(user_id) => Ok(user_id),
    }
}

impl UserDatabaseConnection for UserSession {
    fn get_connection(&self) -> Result<DBConnection, String> {
        self.get_db_connection().map_err(|e| format!("{:?}", e))
    }
}

const USER_ID_CACHE_KEY: &str = "user_id";
