use flowy_database::{schema::user_table, DBConnection, Database};
use flowy_error::FlowyError;
use flowy_user_data_model::entities::{SignInResponse, SignUpResponse, UpdateUserParams, UserProfile};
use lazy_static::lazy_static;
use lib_sqlite::ConnectionPool;
use once_cell::sync::Lazy;
use parking_lot::{Mutex, RwLock};
use std::{collections::HashMap, sync::Arc, time::Duration};

lazy_static! {
    static ref DB: RwLock<Option<Database>> = RwLock::new(None);
}

pub(crate) struct UserDB {
    db_dir: String,
}

impl UserDB {
    pub(crate) fn new(db_dir: &str) -> Self {
        Self {
            db_dir: db_dir.to_owned(),
        }
    }

    fn open_user_db(&self, user_id: &str) -> Result<(), FlowyError> {
        if user_id.is_empty() {
            return Err(FlowyError::internal().context("user id is empty"));
        }

        tracing::info!("open user db {}", user_id);
        let dir = format!("{}/{}", self.db_dir, user_id);
        let db = flowy_database::init(&dir).map_err(|e| {
            log::error!("init user db failed, {:?}, user_id: {}", e, user_id);
            FlowyError::internal().context(e)
        })?;

        match DB_MAP.try_write_for(Duration::from_millis(300)) {
            None => Err(FlowyError::internal().context("Acquire write lock to save user db failed")),
            Some(mut write_guard) => {
                write_guard.insert(user_id.to_owned(), db);
                Ok(())
            },
        }
    }

    pub(crate) fn close_user_db(&self, user_id: &str) -> Result<(), FlowyError> {
        match DB_MAP.try_write_for(Duration::from_millis(300)) {
            None => Err(FlowyError::internal().context("Acquire write lock to close user db failed")),
            Some(mut write_guard) => {
                set_user_db_init(false, user_id);
                write_guard.remove(user_id);
                Ok(())
            },
        }
    }

    pub(crate) fn get_connection(&self, user_id: &str) -> Result<DBConnection, FlowyError> {
        let conn = self.get_pool(user_id)?.get()?;
        Ok(conn)
    }

    pub(crate) fn get_pool(&self, user_id: &str) -> Result<Arc<ConnectionPool>, FlowyError> {
        // Opti: INIT_LOCK try to lock the INIT_RECORD accesses. Because the write guard
        // can not nested in the read guard that will cause the deadlock.
        match INIT_LOCK.try_lock_for(Duration::from_millis(300)) {
            None => log::error!("get_pool fail"),
            Some(_) => {
                if !is_user_db_init(user_id) {
                    let _ = self.open_user_db(user_id)?;
                    set_user_db_init(true, user_id);
                }
            },
        }

        match DB_MAP.try_read_for(Duration::from_millis(300)) {
            None => Err(FlowyError::internal().context("Acquire read lock to read user db failed")),
            Some(read_guard) => match read_guard.get(user_id) {
                None => {
                    Err(FlowyError::internal().context("Get connection failed. The database is not initialization"))
                },
                Some(database) => Ok(database.get_pool()),
            },
        }
    }
}

lazy_static! {
    static ref DB_MAP: RwLock<HashMap<String, Database>> = RwLock::new(HashMap::new());
}

static INIT_LOCK: Lazy<Mutex<()>> = Lazy::new(|| Mutex::new(()));
static INIT_RECORD: Lazy<Mutex<HashMap<String, bool>>> = Lazy::new(|| Mutex::new(HashMap::new()));
fn set_user_db_init(is_init: bool, user_id: &str) {
    let mut record = INIT_RECORD.lock();
    record.insert(user_id.to_owned(), is_init);
}

fn is_user_db_init(user_id: &str) -> bool {
    match INIT_RECORD.lock().get(user_id) {
        None => false,
        Some(flag) => *flag,
    }
}

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct UserTable {
    pub(crate) id: String,
    pub(crate) name: String,
    pub(crate) token: String,
    pub(crate) email: String,
    pub(crate) workspace: String, // deprecated
}

impl UserTable {
    pub fn new(id: String, name: String, email: String, token: String) -> Self {
        Self {
            id,
            name,
            email,
            token,
            workspace: "".to_owned(),
        }
    }

    pub fn set_workspace(mut self, workspace: String) -> Self {
        self.workspace = workspace;
        self
    }
}

impl std::convert::From<SignUpResponse> for UserTable {
    fn from(resp: SignUpResponse) -> Self { UserTable::new(resp.user_id, resp.name, resp.email, resp.token) }
}

impl std::convert::From<SignInResponse> for UserTable {
    fn from(resp: SignInResponse) -> Self { UserTable::new(resp.user_id, resp.name, resp.email, resp.token) }
}

impl std::convert::From<UserTable> for UserProfile {
    fn from(table: UserTable) -> Self {
        UserProfile {
            id: table.id,
            email: table.email,
            name: table.name,
            token: table.token,
        }
    }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "user_table"]
pub struct UserTableChangeset {
    pub id: String,
    pub workspace: Option<String>, // deprecated
    pub name: Option<String>,
    pub email: Option<String>,
}

impl UserTableChangeset {
    pub fn new(params: UpdateUserParams) -> Self {
        UserTableChangeset {
            id: params.id,
            workspace: None,
            name: params.name,
            email: params.email,
        }
    }
}
