use crate::{
    entities::revision::{RepeatedRevision, Revision},
    errors::CollaborateError,
};
use flowy_derive::ProtoBuf;
use lib_ot::{errors::OTError, text_delta::TextOperations};

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateDocumentParams {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub revisions: RepeatedRevision,
}

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct DocumentPayloadPB {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub content: String,

    #[pb(index = 3)]
    pub rev_id: i64,

    #[pb(index = 4)]
    pub base_rev_id: i64,
}

impl std::convert::TryFrom<Revision> for DocumentPayloadPB {
    type Error = CollaborateError;

    fn try_from(revision: Revision) -> Result<Self, Self::Error> {
        if !revision.is_initial() {
            return Err(CollaborateError::revision_conflict()
                .context("Revision's rev_id should be 0 when creating the document"));
        }

        let delta = TextOperations::from_bytes(&revision.bytes)?;
        let doc_json = delta.json_str();

        Ok(DocumentPayloadPB {
            doc_id: revision.object_id,
            content: doc_json,
            rev_id: revision.rev_id,
            base_rev_id: revision.base_rev_id,
        })
    }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct ResetDocumentParams {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub revisions: RepeatedRevision,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct DocumentOperationsPB {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub operations_str: String,
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct NewDocUserPB {
    #[pb(index = 1)]
    pub user_id: String,

    #[pb(index = 2)]
    pub rev_id: i64,

    #[pb(index = 3)]
    pub doc_id: String,
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
