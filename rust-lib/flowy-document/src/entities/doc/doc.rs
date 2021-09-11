use crate::{
    entities::doc::parser::*,
    errors::{ErrorBuilder, *},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateDocParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: String,
}

impl CreateDocParams {
    pub fn new(id: &str, data: &str) -> Self {
        Self {
            id: id.to_owned(),
            data: data.to_owned(),
        }
    }
}

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct Doc {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UpdateDocParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub data: Option<String>,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct QueryDocParams {
    #[pb(index = 1)]
    pub doc_id: String,
}
