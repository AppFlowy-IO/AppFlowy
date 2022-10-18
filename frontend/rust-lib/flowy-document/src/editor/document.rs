use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::{RevisionObjectDeserializer, RevisionObjectSerializer};
use flowy_sync::entities::document::DocumentPayloadPB;
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_operations_from_revisions;
use lib_ot::core::{AttributeHashMap, NodeTree, Transaction};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct Document {
    #[serde(serialize_with = "serialize_tree")]
    #[serde(deserialize_with = "deserialize_tree")]
    tree: NodeTree,
}

impl Document {
    pub fn from_transaction(transaction: Transaction) -> FlowyResult<Self> {
        let tree = NodeTree::from_operations("root", transaction.operations)?;
        Ok(Self { tree })
    }
}

// pub struct DocumentRevisionSerde();
// impl RevisionObjectDeserializer for DocumentRevisionSerde {
//     type Output = DocumentPayloadPB;
//
//     fn deserialize_revisions(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
//         let (base_rev_id, rev_id) = revisions.last().unwrap().pair_rev_id();
//
//         for revision in revisions {
//             let transaction = Transaction::from_bytes(&revision.bytes)?;
//         }
//
//         let mut delta = make_operations_from_revisions(revisions)?;
//         correct_delta(&mut delta);
//
//         Result::<DocumentPayloadPB, FlowyError>::Ok(DocumentPayloadPB {
//             doc_id: object_id.to_owned(),
//             content: delta.json_str(),
//             rev_id,
//             base_rev_id,
//         })
//     }
// }
//
// impl RevisionObjectSerializer for DocumentRevisionSerde {
//     fn serialize_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
//         let operations = make_operations_from_revisions::<AttributeHashMap>(revisions)?;
//         Ok(operations.json_bytes())
//     }
// }
