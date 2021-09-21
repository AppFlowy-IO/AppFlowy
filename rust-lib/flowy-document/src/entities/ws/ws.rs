use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Debug, Clone, ProtoBuf_Enum, Eq, PartialEq, Hash)]
pub enum WsSource {
    Delta = 0,
}

impl std::default::Default for WsSource {
    fn default() -> Self { WsSource::Delta }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct WsDocumentData {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub source: WsSource,

    #[pb(index = 3)]
    pub data: Vec<u8>, // Delta
}
