use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

const OBSERVABLE_CATEGORY: &str = "Grid";

#[derive(ProtoBuf_Enum, Debug)]
pub enum DatabaseNotification {
  Unknown = 0,
  /// Trigger after inserting/deleting/updating a row
  DidUpdateViewRows = 20,
  /// Trigger when the visibility of the row was changed. For example, updating the filter will trigger the notification
  DidUpdateViewRowsVisibility = 21,
  /// Trigger after inserting/deleting/updating a field
  DidUpdateFields = 22,
  /// Trigger after editing a cell
  DidUpdateCell = 40,
  /// Trigger after editing a field properties including rename,update type option, etc
  DidUpdateField = 50,
  /// Trigger after the number of groups is changed
  DidUpdateNumOfGroups = 60,
  /// Trigger after inserting/deleting/updating/moving a row
  DidUpdateGroupRow = 61,
  /// Trigger when setting a new grouping field
  DidGroupByField = 62,
  /// Trigger after inserting/deleting/updating a filter
  DidUpdateFilter = 63,
  /// Trigger after inserting/deleting/updating a sort
  DidUpdateSort = 64,
  /// Trigger after the sort configurations are changed
  DidReorderRows = 65,
  /// Trigger after editing the row that hit the sort rule
  DidReorderSingleRow = 66,
  /// Trigger when the settings of the database are changed
  DidUpdateSettings = 70,
  // Trigger when the layout setting of the database is updated
  DidUpdateLayoutSettings = 80,
  // Trigger when the layout field of the database is changed
  DidSetNewLayoutField = 81,
  // Trigger when the layout of the database is changed
  DidUpdateDatabaseLayout = 82,
  // Trigger when the database view is deleted
  DidDeleteDatabaseView = 83,
  // Trigger when the database view is moved to trash
  DidMoveDatabaseViewToTrash = 84,
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
