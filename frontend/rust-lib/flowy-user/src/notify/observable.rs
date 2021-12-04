use dart_notify::DartNotifyBuilder;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

const OBSERVABLE_CATEGORY: &str = "User";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum UserNotification {
    Unknown            = 0,
    UserAuthChanged    = 1,
    UserProfileUpdated = 2,
    UserUnauthorized   = 3,
    UserWsConnectStateChanged = 4,
}

impl std::default::Default for UserNotification {
    fn default() -> Self { UserNotification::Unknown }
}

impl std::convert::From<UserNotification> for i32 {
    fn from(notification: UserNotification) -> Self { notification as i32 }
}

pub(crate) fn dart_notify(id: &str, ty: UserNotification) -> DartNotifyBuilder {
    DartNotifyBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}

#[derive(ProtoBuf_Enum, Debug, Clone)]
pub enum NetworkType {
    UnknownNetworkType = 0,
    Wifi               = 1,
    Cell               = 2,
    Ethernet           = 3,
}

impl std::default::Default for NetworkType {
    fn default() -> Self { NetworkType::UnknownNetworkType }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct NetworkState {
    #[pb(index = 1)]
    pub ty: NetworkType,
}
