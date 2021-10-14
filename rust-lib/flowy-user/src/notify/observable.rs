use flowy_derive::ProtoBuf_Enum;

use flowy_dart_notify::DartNotifyBuilder;

const OBSERVABLE_CATEGORY: &'static str = "User";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum UserNotification {
    Unknown            = 0,
    UserAuthChanged    = 1,
    UserProfileUpdated = 2,
    UserUnauthorized   = 3,
}

impl std::default::Default for UserNotification {
    fn default() -> Self { UserNotification::Unknown }
}

impl std::convert::Into<i32> for UserNotification {
    fn into(self) -> i32 { self as i32 }
}

pub(crate) fn dart_notify(id: &str, ty: UserNotification) -> DartNotifyBuilder {
    DartNotifyBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}
