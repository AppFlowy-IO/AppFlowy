use crate::entities::{RepeatedView, ViewDataType};
use crate::parser::view::ViewIdentify;
use flowy_derive::ProtoBuf;
use flowy_error_code::ErrorCode;
use std::convert::TryInto;

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
    pub ext_data: ViewExtData,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewExtData {
    #[pb(index = 1)]
    pub filter: ViewFilter,

    #[pb(index = 2)]
    pub group: ViewGroup,

    #[pb(index = 3)]
    pub sort: ViewSort,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewFilter {
    #[pb(index = 1)]
    pub field_id: String,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewGroup {
    #[pb(index = 1)]
    pub group_field_id: String,

    #[pb(index = 2, one_of)]
    pub sub_group_field_id: Option<String>,
}

#[derive(Eq, PartialEq, ProtoBuf, Debug, Default, Clone)]
pub struct ViewSort {
    #[pb(index = 1)]
    pub field_id: String,
}

#[derive(Default, ProtoBuf)]
pub struct UpdateViewInfoPayload {
    #[pb(index = 1)]
    pub view_id: String,

    #[pb(index = 2, one_of)]
    pub filter: Option<ViewFilter>,

    #[pb(index = 3, one_of)]
    pub group: Option<ViewGroup>,

    #[pb(index = 4, one_of)]
    pub sort: Option<ViewSort>,
}

pub struct UpdateViewInfoParams {
    pub view_id: String,
    pub filter: Option<ViewFilter>,
    pub group: Option<ViewGroup>,
    pub sort: Option<ViewSort>,
}
