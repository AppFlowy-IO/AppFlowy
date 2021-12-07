use flowy_derive::ProtoBuf;
use lib_ot::{errors::OTError, rich_text::RichTextDelta};

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateDocParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: String,
}

impl CreateDocParams {
    pub fn new(id: &str, data: String) -> Self {
        Self {
            id: id.to_owned(),
            data,
        }
    }
}

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct Doc {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub data: String,

    #[pb(index = 3)]
    pub rev_id: i64,

    #[pb(index = 4)]
    pub base_rev_id: i64,
}

impl Doc {
    pub fn delta(&self) -> Result<RichTextDelta, OTError> {
        let delta = RichTextDelta::from_bytes(&self.data)?;
        Ok(delta)
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UpdateDocParams {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub data: String,

    #[pb(index = 3)]
    pub rev_id: i64,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocDelta {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub data: String, // RichTextDelta
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct NewDocUser {
    #[pb(index = 1)]
    pub user_id: String,

    #[pb(index = 2)]
    pub rev_id: i64,

    #[pb(index = 3)]
    pub doc_id: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocIdentifier {
    #[pb(index = 1)]
    pub doc_id: String,
}

impl std::convert::From<String> for DocIdentifier {
    fn from(doc_id: String) -> Self { DocIdentifier { doc_id } }
}

impl std::convert::From<&String> for DocIdentifier {
    fn from(doc_id: &String) -> Self {
        DocIdentifier {
            doc_id: doc_id.to_owned(),
        }
    }
}
