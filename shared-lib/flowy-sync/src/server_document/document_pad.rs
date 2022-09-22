use crate::synchronizer::RevisionOperations;
use crate::{client_document::InitialDocumentText, errors::CollaborateError, synchronizer::RevisionSyncObject};
use lib_ot::{core::*, text_delta::TextOperations};

pub struct ServerDocument {
    doc_id: String,
    operations: TextOperations,
}

impl ServerDocument {
    #[allow(dead_code)]
    pub fn new<C: InitialDocumentText>(doc_id: &str) -> Self {
        Self::from_delta(doc_id, C::initial_delta())
    }

    pub fn from_delta(doc_id: &str, operations: TextOperations) -> Self {
        let doc_id = doc_id.to_owned();
        ServerDocument { doc_id, operations }
    }
}

impl RevisionSyncObject<AttributeHashMap> for ServerDocument {
    fn id(&self) -> &str {
        &self.doc_id
    }

    fn compose(&mut self, other: &TextOperations) -> Result<(), CollaborateError> {
        // tracing::trace!("{} compose {}", &self.delta.to_json(), other.to_json());
        let operations = self.operations.compose(other)?;
        self.operations = operations;
        Ok(())
    }

    fn transform(&self, other: &TextOperations) -> Result<(TextOperations, TextOperations), CollaborateError> {
        let value = self.operations.transform(other)?;
        Ok(value)
    }

    fn to_json(&self) -> String {
        self.operations.json_str()
    }

    fn set_operations(&mut self, operations: RevisionOperations<AttributeHashMap>) {
        self.operations = operations;
    }
}
