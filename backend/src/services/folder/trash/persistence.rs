use crate::services::folder::{app::persistence::AppTable, view::persistence::ViewTable};
use flowy_folder_data_model::protobuf::{Trash, TrashType};

pub(crate) const TRASH_TABLE: &str = "trash_table";

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct TrashTable {
    pub(crate) id: uuid::Uuid,
    #[allow(dead_code)]
    pub(crate) user_id: String,
    pub(crate) ty: i32,
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
