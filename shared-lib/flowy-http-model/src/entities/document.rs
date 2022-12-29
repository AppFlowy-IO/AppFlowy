use crate::revision::Revision;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct CreateDocumentParams {
    pub doc_id: String,
    pub revisions: Vec<Revision>,
}

#[derive(Serialize, Deserialize, Default, Debug, Clone, Eq, PartialEq)]
pub struct DocumentPayload {
    pub doc_id: String,
    pub data: Vec<u8>,
    pub rev_id: i64,
    pub base_rev_id: i64,
}

impl std::convert::TryFrom<Revision> for DocumentPayload {
    type Error = String;

    fn try_from(revision: Revision) -> Result<Self, Self::Error> {
        if !revision.is_initial() {
            return Err("Revision's rev_id should be 0 when creating the document".to_string());
        }

        Ok(DocumentPayload {
            doc_id: revision.object_id,
            data: revision.bytes,
            rev_id: revision.rev_id,
            base_rev_id: revision.base_rev_id,
        })
    }
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct ResetDocumentParams {
    pub doc_id: String,
    pub revisions: Vec<Revision>,
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct DocumentId {
    pub value: String,
}
impl AsRef<str> for DocumentId {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

impl std::convert::From<String> for DocumentId {
    fn from(value: String) -> Self {
        DocumentId { value }
    }
}

impl std::convert::From<DocumentId> for String {
    fn from(block_id: DocumentId) -> Self {
        block_id.value
    }
}

impl std::convert::From<&String> for DocumentId {
    fn from(s: &String) -> Self {
        DocumentId { value: s.to_owned() }
    }
}
