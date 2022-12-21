use dart_notify::DartNotifyBuilder;
use flowy_derive::ProtoBuf_Enum;
const OBSERVABLE_CATEGORY: &str = "Grid";

#[derive(ProtoBuf_Enum, Debug)]
pub enum GridDartNotification {
    Unknown = 0,
    DidCreateBlock = 11,
    DidUpdateGridViewRows = 20,
    DidUpdateGridViewRowsVisibility = 21,
    DidUpdateGridFields = 22,
    DidUpdateRow = 30,
    DidUpdateCell = 40,
    DidUpdateField = 50,
    DidUpdateGroupView = 60,
    DidUpdateGroup = 61,
    DidGroupByNewField = 62,
    DidUpdateFilter = 63,
    DidUpdateSort = 64,
    DidUpdateGridSetting = 70,
}

impl std::default::Default for GridDartNotification {
    fn default() -> Self {
        GridDartNotification::Unknown
    }
}

impl std::convert::From<GridDartNotification> for i32 {
    fn from(notification: GridDartNotification) -> Self {
        notification as i32
    }
}

#[tracing::instrument(level = "trace")]
pub fn send_dart_notification(id: &str, ty: GridDartNotification) -> DartNotifyBuilder {
    DartNotifyBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}
