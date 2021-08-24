// type mapped https://kotiri.com/2018/01/31/postgresql-diesel-rust-types.html

use chrono::Utc;

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct UserTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) email: String,
    pub(crate) name: String,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) password: String,
}
