use crate::errors::*;
use diesel::{connection::Connection, SqliteConnection};
use r2d2::{ManageConnection, Pool};
use scheduled_thread_pool::ScheduledThreadPool;
use std::{
    sync::{
        atomic::{AtomicUsize, Ordering::SeqCst},
        Arc,
    },
    time::Duration,
};

lazy_static::lazy_static! {
    static ref DB_POOL: Arc<ScheduledThreadPool> = Arc::new(
        ScheduledThreadPool::with_name("db-pool-{}:", 4)
    );
}

pub struct ConnectionPool {
    pub(crate) inner: Pool<ConnectionManager>,
}

impl std::ops::Deref for ConnectionPool {
    type Target = Pool<ConnectionManager>;

    fn deref(&self) -> &Self::Target { &self.inner }
}

impl ConnectionPool {
    pub fn new<T>(config: PoolConfig, uri: T) -> Result<Self>
    where
        T: Into<String>,
    {
        let manager = ConnectionManager::new(uri);
        let thread_pool = DB_POOL.clone();
        let config = Arc::new(config);

        let pool = r2d2::Pool::builder()
            .thread_pool(thread_pool)
            .min_idle(Some(config.min_idle))
            .max_size(config.max_size)
            .max_lifetime(None)
            .connection_timeout(config.connection_timeout)
            .idle_timeout(Some(config.idle_timeout))
            .build_unchecked(manager);
        Ok(ConnectionPool { inner: pool })
    }
}

#[derive(Default, Debug, Clone)]
pub struct ConnCounter(Arc<ConnCounterInner>);

impl std::ops::Deref for ConnCounter {
    type Target = ConnCounterInner;

    fn deref(&self) -> &Self::Target { &*self.0 }
}

#[derive(Default, Debug)]
pub struct ConnCounterInner {
    max_number: AtomicUsize,
    current_number: AtomicUsize,
}

impl ConnCounterInner {
    pub fn get_max_num(&self) -> usize { self.max_number.load(SeqCst) }

    pub fn reset(&self) {
        // reset max_number to current_number
        let _ = self
            .max_number
            .fetch_update(SeqCst, SeqCst, |_| Some(self.current_number.load(SeqCst)));
    }
}

pub type OnExecFunc = Box<dyn Fn() -> Box<dyn Fn(&SqliteConnection, &str)> + Send + Sync>;

pub struct PoolConfig {
    min_idle: u32,
    max_size: u32,
    connection_timeout: Duration,
    idle_timeout: Duration,
}

impl Default for PoolConfig {
    fn default() -> Self {
        Self {
            min_idle: 1,
            max_size: 10,
            connection_timeout: Duration::from_secs(10),
            idle_timeout: Duration::from_secs(5 * 60),
        }
    }
}

impl PoolConfig {
    #[allow(dead_code)]
    pub fn min_idle(mut self, min_idle: u32) -> Self {
        self.min_idle = min_idle;
        self
    }

    #[allow(dead_code)]
    pub fn max_size(mut self, max_size: u32) -> Self {
        self.max_size = max_size;
        self
    }
}

pub struct ConnectionManager {
    db_uri: String,
}

impl ManageConnection for ConnectionManager {
    type Connection = SqliteConnection;
    type Error = crate::Error;

    fn connect(&self) -> Result<Self::Connection> { Ok(SqliteConnection::establish(&self.db_uri)?) }

    fn is_valid(&self, conn: &mut Self::Connection) -> Result<()> {
        Ok(conn.execute("SELECT 1").map(|_| ())?)
    }

    fn has_broken(&self, _conn: &mut Self::Connection) -> bool { false }
}

impl ConnectionManager {
    pub fn new<S: Into<String>>(uri: S) -> Self { ConnectionManager { db_uri: uri.into() } }
}
