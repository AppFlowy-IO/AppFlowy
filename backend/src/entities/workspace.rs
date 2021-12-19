use chrono::Utc;
use flowy_core_data_model::protobuf::{App, RepeatedView, Trash, TrashType, View, ViewType, Workspace};
use protobuf::ProtobufEnum;

pub(crate) const WORKSPACE_TABLE: &str = "workspace_table";
pub(crate) const APP_TABLE: &str = "app_table";
pub(crate) const VIEW_TABLE: &str = "view_table";
pub(crate) const TRASH_TABLE: &str = "trash_table";

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct WorkspaceTable {
    pub(crate) id: uuid::Uuid,
    pub(crate) name: String,
    pub(crate) description: String,
    pub(crate) modified_time: chrono::DateTime<Utc>,
    pub(crate) create_time: chrono::DateTime<Utc>,
    pub(crate) user_id: String,
}
impl std::convert::From<WorkspaceTable> for Workspace {
    fn from(table: WorkspaceTable) -> Self {
        let mut workspace = Workspace::default();
        workspace.set_id(table.id.to_string());
        workspace.set_name(table.name.clone());
        workspace.set_desc(table.description.clone());
        workspace.set_modified_time(table.modified_time.timestamp());
        workspace.set_create_time(table.create_time.timestamp());
        workspace
    }
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
}
impl std::convert::From<AppTable> for App {
    fn from(table: AppTable) -> Self {
        let mut app = App::default();
        app.set_id(table.id.to_string());
        app.set_workspace_id(table.workspace_id.to_string());
        app.set_name(table.name.clone());
        app.set_desc(table.description.clone());
        app.set_belongings(RepeatedView::default());
        app.set_modified_time(table.modified_time.timestamp());
        app.set_create_time(table.create_time.timestamp());

        app
    }
}

impl std::convert::From<AppTable> for Trash {
    fn from(table: AppTable) -> Self {
        Trash {
            id: table.id.to_string(),
            name: table.name,
            modified_time: table.modified_time.timestamp(),
            create_time: table.create_time.timestamp(),
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
impl std::convert::From<ViewTable> for View {
    fn from(table: ViewTable) -> Self {
        let view_type = ViewType::from_i32(table.view_type).unwrap_or(ViewType::Doc);

        let mut view = View::default();
        view.set_id(table.id.to_string());
        view.set_belong_to_id(table.belong_to_id);
        view.set_name(table.name);
        view.set_desc(table.description);
        view.set_view_type(view_type);
        view.set_belongings(RepeatedView::default());
        view.set_create_time(table.create_time.timestamp());
        view.set_modified_time(table.modified_time.timestamp());

        view
    }
}

impl std::convert::From<ViewTable> for Trash {
    fn from(table: ViewTable) -> Self {
        Trash {
            id: table.id.to_string(),
            name: table.name,
            modified_time: table.modified_time.timestamp(),
            create_time: table.create_time.timestamp(),
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
