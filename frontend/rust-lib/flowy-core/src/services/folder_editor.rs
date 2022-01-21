use crate::services::{persistence::FOLDER_ID, web_socket::make_folder_ws_manager};
use flowy_collaboration::{
    entities::{revision::Revision, ws_data::ServerRevisionWSData},
    folder::{FolderChange, FolderPad},
};

use flowy_error::{FlowyError, FlowyResult};
use flowy_sync::{
    RevisionCache,
    RevisionCloudService,
    RevisionManager,
    RevisionObjectBuilder,
    RevisionWebSocket,
    RevisionWebSocketManager,
};
use lib_infra::future::FutureResult;
use lib_sqlite::ConnectionPool;
use parking_lot::RwLock;
use std::sync::Arc;

pub struct FolderEditor {
    user_id: String,
    pub(crate) folder: Arc<RwLock<FolderPad>>,
    rev_manager: Arc<RevisionManager>,
    ws_manager: Arc<RevisionWebSocketManager>,
}

impl FolderEditor {
    pub async fn new(
        user_id: &str,
        token: &str,
        pool: Arc<ConnectionPool>,
        web_socket: Arc<dyn RevisionWebSocket>,
    ) -> FlowyResult<Self> {
        let cache = Arc::new(RevisionCache::new(user_id, FOLDER_ID, pool));
        let mut rev_manager = RevisionManager::new(user_id, FOLDER_ID, cache);
        let cloud = Arc::new(FolderRevisionCloudServiceImpl {
            token: token.to_string(),
        });
        let folder_pad = Arc::new(RwLock::new(rev_manager.load::<FolderPadBuilder>(cloud).await?));
        let rev_manager = Arc::new(rev_manager);
        let ws_manager = make_folder_ws_manager(user_id, rev_manager.clone(), web_socket, folder_pad.clone()).await;

        let user_id = user_id.to_owned();
        Ok(Self {
            user_id,
            folder: folder_pad,
            rev_manager,
            ws_manager,
        })
    }

    pub async fn receive_ws_data(&self, data: ServerRevisionWSData) -> FlowyResult<()> {
        let _ = self.ws_manager.ws_passthrough_tx.send(data).await.map_err(|e| {
            let err_msg = format!("{} passthrough error: {}", FOLDER_ID, e);
            FlowyError::internal().context(err_msg)
        })?;
        Ok(())
    }

    pub(crate) fn apply_change(&self, change: FolderChange) -> FlowyResult<()> {
        let FolderChange { delta, md5 } = change;
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.to_bytes();
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &self.user_id,
            md5,
        );
        let _ = futures::executor::block_on(async { self.rev_manager.add_local_revision(&revision).await })?;
        Ok(())
    }
}

struct FolderPadBuilder();
impl RevisionObjectBuilder for FolderPadBuilder {
    type Output = FolderPad;

    fn build_with_revisions(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = FolderPad::from_revisions(revisions)?;
        Ok(pad)
    }
}

struct FolderRevisionCloudServiceImpl {
    #[allow(dead_code)]
    token: String,
    // server: Arc<dyn FolderCouldServiceV2>,
}

impl RevisionCloudService for FolderRevisionCloudServiceImpl {
    #[tracing::instrument(level = "debug", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}
