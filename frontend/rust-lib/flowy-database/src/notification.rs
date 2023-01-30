use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
const OBSERVABLE_CATEGORY: &str = "Grid";

#[derive(ProtoBuf_Enum, Debug)]
pub enum DatabaseNotification {
    Unknown = 0,
    DidCreateBlock = 11,
    DidUpdateDatabaseViewRows = 20,
    DidUpdateDatabaseViewRowsVisibility = 21,
    DidUpdateDatabaseFields = 22,
    DidUpdateRow = 30,
    DidUpdateCell = 40,
    DidUpdateField = 50,
    DidUpdateGroupView = 60,
    DidUpdateGroup = 61,
    DidGroupByNewField = 62,
    DidUpdateFilter = 63,
    DidUpdateSort = 64,
    DidReorderRows = 65,
    DidReorderSingleRow = 66,
    DidUpdateDatabaseSetting = 70,
}

impl std::default::Default for DatabaseNotification {
    fn default() -> Self {
        DatabaseNotification::Unknown
    }
}

impl std::convert::From<DatabaseNotification> for i32 {
    fn from(notification: DatabaseNotification) -> Self {
        notification as i32
    }
}

#[tracing::instrument(level = "trace")]
pub fn send_notification(id: &str, ty: DatabaseNotification) -> NotificationBuilder {
    NotificationBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}
