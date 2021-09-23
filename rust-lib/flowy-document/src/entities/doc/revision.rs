use flowy_derive::ProtoBuf;

#[derive(Debug, Clone, Default, ProtoBuf)]
pub struct Revision {
    #[pb(index = 1)]
    pub base_rev_id: i64,

    #[pb(index = 2)]
    pub rev_id: i64,

    #[pb(index = 3)]
    pub delta: Vec<u8>,

    #[pb(index = 4)]
    pub md5: String,

    #[pb(index = 5)]
    pub doc_id: String,
}

impl Revision {
    pub fn new(base_rev_id: i64, rev_id: i64, delta: Vec<u8>, md5: String, doc_id: String) -> Revision {
        Self {
            base_rev_id,
            rev_id,
            delta,
            md5,
            doc_id,
        }
    }
}
