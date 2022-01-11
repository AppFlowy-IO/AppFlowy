mod local_server;
mod local_ws;
mod persistence;

use flowy_collaboration::errors::CollaborateError;
pub use local_ws::*;

use flowy_collaboration::protobuf::RepeatedRevision as RepeatedRevisionPB;
use lib_infra::future::BoxResultFuture;

pub trait DocumentCloudStorage: Send + Sync {
    fn set_revisions(&self, repeated_revision: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError>;
    fn get_revisions(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<RepeatedRevisionPB, CollaborateError>;

    fn reset_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError>;
}
