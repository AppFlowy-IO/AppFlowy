use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

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
