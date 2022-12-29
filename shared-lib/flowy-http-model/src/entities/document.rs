use flowy_derive::ProtoBuf;
use crate::revision::Revision;

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateDocumentParams {
    #[pb(index = 1)]
    pub doc_id: String,

    // #[pb(index = 2)]
    // pub revisions: RepeatedRevision,
}

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct DocumentPayloadPB {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,

    #[pb(index = 3)]
    pub rev_id: i64,

    #[pb(index = 4)]
    pub base_rev_id: i64,
}

impl std::convert::TryFrom<Revision> for DocumentPayloadPB {
    type Error = String;

    fn try_from(revision: Revision) -> Result<Self, Self::Error> {
        if !revision.is_initial() {
            return Err("Revision's rev_id should be 0 when creating the document".to_string());
        }

        Ok(DocumentPayloadPB {
            doc_id: revision.object_id,
            data: revision.bytes,
            rev_id: revision.rev_id,
            base_rev_id: revision.base_rev_id,
        })
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ResetDocumentParams {
    #[pb(index = 1)]
    pub doc_id: String,

    // #[pb(index = 2)]
    // pub revisions: RepeatedRevision,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocumentIdPB {
    #[pb(index = 1)]
    pub value: String,
}
impl AsRef<str> for DocumentIdPB {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

impl std::convert::From<String> for DocumentIdPB {
    fn from(value: String) -> Self {
        DocumentIdPB { value }
    }
}

impl std::convert::From<DocumentIdPB> for String {
    fn from(block_id: DocumentIdPB) -> Self {
        block_id.value
    }
}

impl std::convert::From<&String> for DocumentIdPB {
    fn from(s: &String) -> Self {
        DocumentIdPB { value: s.to_owned() }
    }
}
