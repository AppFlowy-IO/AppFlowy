use chrono::Utc;
use flowy_workspace::backend_service::{App, RepeatedView, Trash, TrashType, View, ViewType};
use protobuf::ProtobufEnum;

pub(crate) const WORKSPACE_TABLE: &'static str = "workspace_table";
pub(crate) const APP_TABLE: &'static str = "app_table";
pub(crate) const VIEW_TABLE: &'static str = "view_table";
pub(crate) const TRASH_TABLE: &'static str = "trash_table";

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
        let mut app = App::default();
        app.set_id(self.id.to_string());
        app.set_workspace_id(self.workspace_id.to_string());
        app.set_name(self.name.clone());
        app.set_desc(self.description.clone());
        app.set_belongings(RepeatedView::default());
        app.set_modified_time(self.modified_time.timestamp());
        app.set_create_time(self.create_time.timestamp());

        app
    }
}

impl std::convert::Into<Trash> for AppTable {
    fn into(self) -> Trash {
        Trash {
            id: self.id.to_string(),
            name: self.name,
            modified_time: self.modified_time.timestamp(),
            create_time: self.create_time.timestamp(),
            ty: TrashType::App,
            unknown_fields: Default::default(),
            cached_size: Default::default(),
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
}

impl std::convert::Into<View> for ViewTable {
    fn into(self) -> View {
        let view_type = ViewType::from_i32(self.view_type).unwrap_or(ViewType::Doc);

        let mut view = View::default();
        view.set_id(self.id.to_string());
        view.set_belong_to_id(self.belong_to_id);
        view.set_name(self.name);
        view.set_desc(self.description);
        view.set_view_type(view_type);
        view.set_belongings(RepeatedView::default());
        view.set_create_time(self.create_time.timestamp());
        view.set_modified_time(self.modified_time.timestamp());

        view
    }
}

impl std::convert::Into<Trash> for ViewTable {
    fn into(self) -> Trash {
        Trash {
            id: self.id.to_string(),
            name: self.name,
            modified_time: self.modified_time.timestamp(),
            create_time: self.create_time.timestamp(),
            ty: TrashType::View,
            unknown_fields: Default::default(),
            cached_size: Default::default(),
        }
    }
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct TrashTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) user_id: String,
    pub(crate) ty: i32,
}
