use crate::entities::{RepeatedView, ViewDataType};
use flowy_derive::ProtoBuf;

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewInfo {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub belong_to_id: String,

    #[pb(index = 3)]
    pub name: String,

    #[pb(index = 4)]
    pub desc: String,

    #[pb(index = 5)]
    pub data_type: ViewDataType,

    #[pb(index = 6)]
    pub belongings: RepeatedView,

    #[pb(index = 7)]
    pub ext_data: String,
}
