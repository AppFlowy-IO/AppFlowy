use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_http_model::revision::Revision;
use flowy_revision::{RevisionMergeable, RevisionObjectDeserializer, RevisionObjectSerializer};
use lib_ot::core::{Extension, NodeDataBuilder, NodeOperation, NodeTree, NodeTreeContext, Selection, Transaction};
use lib_ot::text_delta::DeltaTextOperationBuilder;

#[derive(Debug)]
pub struct Document {
    tree: NodeTree,
}

impl Document {
    pub fn new(tree: NodeTree) -> Self {
        Self { tree }
    }

    pub fn from_transaction(transaction: Transaction) -> FlowyResult<Self> {
        let tree = NodeTree::from_operations(transaction.operations, make_tree_context())?;
        Ok(Self { tree })
    }

    pub fn get_content(&self, pretty: bool) -> FlowyResult<String> {
        if pretty {
            serde_json::to_string_pretty(self).map_err(|err| FlowyError::serde().context(err))
        } else {
            serde_json::to_string(self).map_err(|err| FlowyError::serde().context(err))
        }
    }

    pub fn document_md5(&self) -> String {
        let bytes = self.tree.to_bytes();
        format!("{:x}", md5::compute(&bytes))
    }

    pub fn get_tree(&self) -> &NodeTree {
        &self.tree
    }
}

pub(crate) fn make_tree_context() -> NodeTreeContext {
    NodeTreeContext {}
}

pub fn initial_document_content() -> String {
    let delta = DeltaTextOperationBuilder::new().insert("").build();
    let node_data = NodeDataBuilder::new("text").insert_delta(delta).build();
    let editor_node = NodeDataBuilder::new("editor").add_node_data(node_data).build();
    let node_operation = NodeOperation::Insert {
        path: vec![0].into(),
        nodes: vec![editor_node],
    };
    let extension = Extension::TextSelection {
        before_selection: Selection::default(),
        after_selection: Selection::default(),
    };
    let transaction = Transaction {
        operations: vec![node_operation].into(),
        extension,
    };
    transaction.to_json().unwrap()
}

impl std::ops::Deref for Document {
    type Target = NodeTree;

    fn deref(&self) -> &Self::Target {
        &self.tree
    }
}

impl std::ops::DerefMut for Document {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.tree
    }
}

pub struct DocumentRevisionSerde();
impl RevisionObjectDeserializer for DocumentRevisionSerde {
    type Output = Document;

    fn deserialize_revisions(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let mut tree = NodeTree::new(make_tree_context());
        let transaction = make_transaction_from_revisions(&revisions)?;
        let _ = tree.apply_transaction(transaction)?;
        let document = Document::new(tree);
        Result::<Document, FlowyError>::Ok(document)
    }
}

impl RevisionObjectSerializer for DocumentRevisionSerde {
    fn combine_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let transaction = make_transaction_from_revisions(&revisions)?;
        Ok(Bytes::from(transaction.to_bytes()?))
    }
}

pub(crate) struct DocumentRevisionCompress();
impl RevisionMergeable for DocumentRevisionCompress {
    fn combine_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        DocumentRevisionSerde::combine_revisions(revisions)
    }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub fn make_transaction_from_revisions(revisions: &[Revision]) -> FlowyResult<Transaction> {
    let mut transaction = Transaction::new();
    for revision in revisions {
        let _ = transaction.compose(Transaction::from_bytes(&revision.bytes)?)?;
    }
    Ok(transaction)
}
