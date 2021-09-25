use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateDocParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

impl CreateDocParams {
    pub fn new(id: &str, data: Vec<u8>) -> Self { Self { id: id.to_owned(), data } }
}

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct Doc {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,

    #[pb(index = 3)]
    pub rev_id: i64,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UpdateDocParams {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,

    #[pb(index = 3)]
    pub rev_id: i64,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocDelta {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>, // Delta
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct QueryDocParams {
    #[pb(index = 1)]
    pub doc_id: String,
}
