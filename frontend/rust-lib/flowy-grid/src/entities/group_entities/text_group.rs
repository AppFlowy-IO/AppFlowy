use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct TextGroupConfigurationPB {
    #[pb(index = 1)]
    hide_empty: bool,
}
