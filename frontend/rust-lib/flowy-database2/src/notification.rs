use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

pub(crate) const DATABASE_OBSERVABLE_SOURCE: &str = "Database";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub enum DatabaseNotification {
  #[default]
  Unknown = 0,
  /// Fetch row data from the remote server. It will be triggered if the backend support remote
  /// storage.
  DidFetchRow = 19,
  /// Trigger after inserting/deleting/updating a row
  DidUpdateRow = 20,
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
  /// Trigger after updating the row meta
  DidUpdateRowMeta = 67,
  /// Trigger when the settings of the database are changed
  DidUpdateSettings = 70,
  // Trigger when the layout setting of the database is updated
  DidUpdateLayoutSettings = 80,
  // Trigger when the layout of the database is changed
  DidUpdateDatabaseLayout = 81,
  // Trigger when the database view is deleted
  DidDeleteDatabaseView = 82,
  // Trigger when the database view is moved to trash
  DidMoveDatabaseViewToTrash = 83,
  DidUpdateDatabaseSyncUpdate = 84,
  DidUpdateDatabaseSnapshotState = 85,
  // Trigger when the field setting is changed
  DidUpdateFieldSettings = 86,
  // Trigger when Calculation changed
  DidUpdateCalculation = 87,
}

impl std::convert::From<DatabaseNotification> for i32 {
  fn from(notification: DatabaseNotification) -> Self {
    notification as i32
  }
}

impl std::convert::From<i32> for DatabaseNotification {
  fn from(notification: i32) -> Self {
    match notification {
      19 => DatabaseNotification::DidFetchRow,
      20 => DatabaseNotification::DidUpdateRow,
      21 => DatabaseNotification::DidUpdateViewRowsVisibility,
      22 => DatabaseNotification::DidUpdateFields,
      40 => DatabaseNotification::DidUpdateCell,
      50 => DatabaseNotification::DidUpdateField,
      60 => DatabaseNotification::DidUpdateNumOfGroups,
      61 => DatabaseNotification::DidUpdateGroupRow,
      62 => DatabaseNotification::DidGroupByField,
      63 => DatabaseNotification::DidUpdateFilter,
      64 => DatabaseNotification::DidUpdateSort,
      65 => DatabaseNotification::DidReorderRows,
      66 => DatabaseNotification::DidReorderSingleRow,
      67 => DatabaseNotification::DidUpdateRowMeta,
      70 => DatabaseNotification::DidUpdateSettings,
      80 => DatabaseNotification::DidUpdateLayoutSettings,
      82 => DatabaseNotification::DidUpdateDatabaseLayout,
      83 => DatabaseNotification::DidDeleteDatabaseView,
      84 => DatabaseNotification::DidMoveDatabaseViewToTrash,
      86 => DatabaseNotification::DidUpdateFieldSettings,
      87 => DatabaseNotification::DidUpdateCalculation,
      _ => DatabaseNotification::Unknown,
    }
  }
}

#[tracing::instrument(level = "trace")]
pub fn send_notification(id: &str, ty: DatabaseNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, DATABASE_OBSERVABLE_SOURCE)
}
