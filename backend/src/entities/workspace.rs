use chrono::Utc;

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct WorkspaceTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) name: String,
    pub(crate) description: String,
    pub(crate) modified_time: chrono::DateTime<Utc>,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) user_id: String,
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct AppTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) workspace_id: String,
    pub(crate) name: String,
    pub(crate) description: String,
    pub(crate) color_style: Vec<u8>,
    pub(crate) last_view_id: String,
    pub(crate) modified_time: chrono::DateTime<Utc>,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) user_id: String,
    pub(crate) is_trash: bool,
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct ViewTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) belong_to_id: String,
    pub(crate) name: String,
    pub(crate) description: String,
    pub(crate) modified_time: chrono::DateTime<Utc>,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) thumbnail: String,
    pub(crate) view_type: i32,
    pub(crate) is_trash: bool,
}
