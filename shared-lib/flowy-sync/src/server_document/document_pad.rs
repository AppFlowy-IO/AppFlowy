use crate::{client_document::InitialDocumentText, errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::{core::*, text_delta::TextDelta};

pub struct ServerDocument {
    doc_id: String,
    delta: TextDelta,
}

impl ServerDocument {
    #[allow(dead_code)]
    pub fn new<C: InitialDocumentText>(doc_id: &str) -> Self {
        Self::from_delta(doc_id, C::initial_delta())
    }

    pub fn from_delta(doc_id: &str, delta: TextDelta) -> Self {
        let doc_id = doc_id.to_owned();
        ServerDocument { doc_id, delta }
    }
}

impl RevisionSyncObject<Attributes> for ServerDocument {
    fn id(&self) -> &str {
        &self.doc_id
    }

    fn compose(&mut self, other: &TextDelta) -> Result<(), CollaborateError> {
        // tracing::trace!("{} compose {}", &self.delta.to_json(), other.to_json());
        let new_delta = self.delta.compose(other)?;
        self.delta = new_delta;
        Ok(())
    }

    fn transform(&self, other: &TextDelta) -> Result<(TextDelta, TextDelta), CollaborateError> {
        let value = self.delta.transform(other)?;
        Ok(value)
    }

    fn to_json(&self) -> String {
        self.delta.json_str()
    }

    fn set_delta(&mut self, new_delta: Operations<Attributes>) {
        self.delta = new_delta;
    }
}
