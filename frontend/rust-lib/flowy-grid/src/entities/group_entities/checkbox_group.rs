use flowy_derive::ProtoBuf;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct CheckboxGroupConfigurationPB {
    #[pb(index = 1)]
    pub(crate) hide_empty: bool,
}
