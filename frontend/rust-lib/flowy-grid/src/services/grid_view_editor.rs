use flowy_error::{FlowyError, FlowyResult};

use flowy_revision::{RevisionCloudService, RevisionManager, RevisionObjectBuilder};
use flowy_sync::client_grid::GridViewRevisionPad;
use flowy_sync::entities::revision::Revision;
use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::RwLock;

#[allow(dead_code)]
pub struct GridViewRevisionEditor {
    #[allow(dead_code)]
    pad: Arc<RwLock<GridViewRevisionPad>>,
    #[allow(dead_code)]
    rev_manager: Arc<RevisionManager>,
}

impl GridViewRevisionEditor {
    #[allow(dead_code)]
    pub async fn new(token: &str, mut rev_manager: RevisionManager) -> FlowyResult<Self> {
        let cloud = Arc::new(GridViewRevisionCloudService {
            token: token.to_owned(),
        });
        let view_revision_pad = rev_manager.load::<GridViewRevisionPadBuilder>(Some(cloud)).await?;
        let pad = Arc::new(RwLock::new(view_revision_pad));
        let rev_manager = Arc::new(rev_manager);

        Ok(Self { pad, rev_manager })
    }
}

struct GridViewRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridViewRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridViewRevisionPadBuilder();
impl RevisionObjectBuilder for GridViewRevisionPadBuilder {
    type Output = GridViewRevisionPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridViewRevisionPad::from_revisions(object_id, revisions)?;
        Ok(pad)
    }
}
