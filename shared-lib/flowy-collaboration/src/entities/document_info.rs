use crate::{
    entities::revision::{RepeatedRevision, Revision},
    errors::CollaborateError,
};
use flowy_derive::ProtoBuf;
use lib_ot::{errors::OTError, rich_text::RichTextDelta};

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct CreateDocParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub revisions: RepeatedRevision,
}

#[derive(ProtoBuf, Default, Debug, Clone, Eq, PartialEq)]
pub struct DocumentInfo {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub text: String,

    #[pb(index = 3)]
    pub rev_id: i64,

    #[pb(index = 4)]
    pub base_rev_id: i64,
}

impl DocumentInfo {
    pub fn delta(&self) -> Result<RichTextDelta, OTError> {
        let delta = RichTextDelta::from_bytes(&self.text)?;
        Ok(delta)
    }
}

impl std::convert::TryFrom<Revision> for DocumentInfo {
    type Error = CollaborateError;

    fn try_from(revision: Revision) -> Result<Self, Self::Error> {
        if !revision.is_initial() {
            return Err(CollaborateError::revision_conflict()
                .context("Revision's rev_id should be 0 when creating the document"));
        }

        let delta = RichTextDelta::from_bytes(&revision.delta_data)?;
        let doc_json = delta.to_json();

        Ok(DocumentInfo {
            doc_id: revision.object_id,
            text: doc_json,
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
pub struct DocumentDelta {
    #[pb(index = 1)]
    pub doc_id: String,

    #[pb(index = 2)]
    pub delta_json: String,
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
pub struct DocumentId {
    #[pb(index = 1)]
    pub doc_id: String,
}

impl std::convert::From<String> for DocumentId {
    fn from(doc_id: String) -> Self { DocumentId { doc_id } }
}

impl std::convert::From<&String> for DocumentId {
    fn from(doc_id: &String) -> Self {
        DocumentId {
            doc_id: doc_id.to_owned(),
        }
    }
}
