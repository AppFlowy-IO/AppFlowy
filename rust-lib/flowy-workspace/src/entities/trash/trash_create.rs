use crate::errors::WorkspaceError;
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct CreateTrashParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub modified_time: i64,

    #[pb(index = 4)]
    pub create_time: i64,
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct Trash {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub modified_time: i64,

    #[pb(index = 4)]
    pub create_time: i64,
}

#[derive(PartialEq, Debug, Default, ProtoBuf, Clone)]
pub struct RepeatedTrash {
    #[pb(index = 1)]
    pub items: Vec<Trash>,
}
