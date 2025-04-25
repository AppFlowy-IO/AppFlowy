use crate::entities::AuthStateChangedPB;
use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
use num_enum::{IntoPrimitive, TryFromPrimitive};
use tracing::trace;

const USER_OBSERVABLE_SOURCE: &str = "User";

#[derive(ProtoBuf_Enum, Debug, Default, IntoPrimitive, TryFromPrimitive, Clone)]
#[repr(i32)]
pub(crate) enum UserNotification {
  #[default]
  Unknown = 0,
  UserAuthStateChanged = 1,
  DidUpdateUserProfile = 2,
  DidUpdateUserWorkspaces = 3,
  DidUpdateCloudConfig = 4,
  DidUpdateUserWorkspace = 5,
  DidUpdateWorkspaceSetting = 6,
  DidLoadUserAwareness = 7,
  // TODO: implement reminder observer
  DidUpdateReminder = 8,
  DidOpenWorkspace = 9,
}

#[tracing::instrument(level = "trace", skip_all)]
pub(crate) fn send_notification<T: ToString>(id: T, ty: UserNotification) -> NotificationBuilder {
  trace!("UserNotification: id = {}, ty = {:?}", id.to_string(), ty);
  NotificationBuilder::new(&id.to_string(), ty, USER_OBSERVABLE_SOURCE)
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_auth_state_notification(payload: AuthStateChangedPB) {
  NotificationBuilder::new(
    "auth_state_change_notification",
    UserNotification::UserAuthStateChanged,
    USER_OBSERVABLE_SOURCE,
  )
  .payload(payload)
  .send()
}
