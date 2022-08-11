use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct SelectOptionGroupConfigurationPB {
    #[pb(index = 1)]
    hide_empty: bool,
}
