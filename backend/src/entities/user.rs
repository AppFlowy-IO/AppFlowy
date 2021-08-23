#[derive(Debug, Clone, sqlx::FromRow)]
pub struct User {
    pub(crate) id: uuid::Uuid,
    pub(crate) email: String,
    pub(crate) name: String,
    pub(crate) create_time: i64,
    pub(crate) password: String,
}
