use crate::{client_document::InitialDocumentText, errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::{
    core::*,
    rich_text::{RichTextAttributes, RichTextDelta},
};

pub struct ServerDocument {
    doc_id: String,
    delta: RichTextDelta,
}

impl ServerDocument {
    #[allow(dead_code)]
    pub fn new<C: InitialDocumentText>(doc_id: &str) -> Self {
        Self::from_delta(doc_id, C::initial_delta())
    }

    pub fn from_delta(doc_id: &str, delta: RichTextDelta) -> Self {
        let doc_id = doc_id.to_owned();
        ServerDocument { doc_id, delta }
    }
}

impl RevisionSyncObject<RichTextAttributes> for ServerDocument {
    fn id(&self) -> &str {
        &self.doc_id
    }

    fn compose(&mut self, other: &RichTextDelta) -> Result<(), CollaborateError> {
        // tracing::trace!("{} compose {}", &self.delta.to_json(), other.to_json());
        let new_delta = self.delta.compose(other)?;
        self.delta = new_delta;
        Ok(())
    }

    fn transform(&self, other: &RichTextDelta) -> Result<(RichTextDelta, RichTextDelta), CollaborateError> {
        let value = self.delta.transform(other)?;
        Ok(value)
    }

    fn to_json(&self) -> String {
        self.delta.to_json_str()
    }

    fn set_delta(&mut self, new_delta: Delta<RichTextAttributes>) {
        self.delta = new_delta;
    }
}
