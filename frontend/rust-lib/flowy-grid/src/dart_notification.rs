use dart_notify::DartNotifyBuilder;
use flowy_derive::ProtoBuf_Enum;
const OBSERVABLE_CATEGORY: &str = "Grid";

#[derive(ProtoBuf_Enum, Debug)]
pub enum GridNotification {
    Unknown = 0,
    GridDidUpdateBlock = 10,
    GridDidCreateBlock = 11,

    GridDidUpdateCells = 20,
    GridDidUpdateFields = 30,
}

impl std::default::Default for GridNotification {
    fn default() -> Self {
        GridNotification::Unknown
    }
}

impl std::convert::From<GridNotification> for i32 {
    fn from(notification: GridNotification) -> Self {
        notification as i32
    }
}

#[tracing::instrument(level = "trace")]
pub fn send_dart_notification(id: &str, ty: GridNotification) -> DartNotifyBuilder {
    DartNotifyBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}

#[tracing::instrument(level = "trace")]
pub fn send_anonymous_dart_notification(ty: GridNotification) -> DartNotifyBuilder {
    DartNotifyBuilder::new("", ty, OBSERVABLE_CATEGORY)
}
