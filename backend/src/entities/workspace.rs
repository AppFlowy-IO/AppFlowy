use chrono::Utc;
use flowy_workspace::entities::{
    app::App,
    view::{RepeatedView, View, ViewType},
};

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

impl std::convert::Into<App> for AppTable {
    fn into(self) -> App {
        App {
            id: self.id.to_string(),
            workspace_id: self.workspace_id,
            name: self.name,
            desc: self.description,
            belongings: RepeatedView::default(),
            version: 0,
        }
    }
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

impl std::convert::Into<View> for ViewTable {
    fn into(self) -> View {
        View {
            id: self.id.to_string(),
            belong_to_id: self.belong_to_id,
            name: self.name,
            desc: self.description,
            view_type: ViewType::from(self.view_type),
            version: 0,
            belongings: RepeatedView::default(),
        }
    }
}
