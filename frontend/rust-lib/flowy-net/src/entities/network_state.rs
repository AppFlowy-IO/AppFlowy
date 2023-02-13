use flowy_client_ws::NetworkType;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq)]
pub enum NetworkTypePB {
  Unknown = 0,
  Wifi = 1,
  Cell = 2,
  Ethernet = 3,
  Bluetooth = 4,
  VPN = 5,
}

impl NetworkTypePB {
  pub fn is_connect(&self) -> bool {
    match self {
      NetworkTypePB::Unknown | NetworkTypePB::Bluetooth => false,
      NetworkTypePB::Wifi | NetworkTypePB::Cell | NetworkTypePB::Ethernet | NetworkTypePB::VPN => {
        true
      },
    }
  }
}

impl std::default::Default for NetworkTypePB {
  fn default() -> Self {
    NetworkTypePB::Unknown
  }
}

impl std::convert::From<NetworkTypePB> for NetworkType {
  fn from(ty: NetworkTypePB) -> Self {
    match ty {
      NetworkTypePB::Unknown => NetworkType::Unknown,
      NetworkTypePB::Wifi => NetworkType::Wifi,
      NetworkTypePB::Cell => NetworkType::Cell,
      NetworkTypePB::Ethernet => NetworkType::Ethernet,
      NetworkTypePB::Bluetooth => NetworkType::Bluetooth,
      NetworkTypePB::VPN => NetworkType::VPN,
    }
  }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct NetworkStatePB {
  #[pb(index = 1)]
  pub ty: NetworkTypePB,
}
