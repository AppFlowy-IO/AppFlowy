use crate::manager::FolderId;
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::{
    RevisionCloudService, RevisionCompress, RevisionManager, RevisionObjectDeserializer, RevisionObjectSerializer,
    RevisionWebSocket,
};
use flowy_sync::util::make_operations_from_revisions;
use flowy_sync::{
    client_folder::{FolderChangeset, FolderPad},
    entities::{revision::Revision, ws_data::ServerRevisionWSData},
};
use lib_infra::future::FutureResult;

use lib_ot::core::EmptyAttributes;
use parking_lot::RwLock;
use std::sync::Arc;

pub struct FolderEditor {
    user_id: String,
    #[allow(dead_code)]
    pub(crate) folder_id: FolderId,
    pub(crate) folder: Arc<RwLock<FolderPad>>,
    rev_manager: Arc<RevisionManager>,
    #[cfg(feature = "sync")]
    ws_manager: Arc<flowy_revision::RevisionWebSocketManager>,
}

impl FolderEditor {
    #[allow(unused_variables)]
    pub async fn new(
        user_id: &str,
        folder_id: &FolderId,
        token: &str,
        mut rev_manager: RevisionManager,
        web_socket: Arc<dyn RevisionWebSocket>,
    ) -> FlowyResult<Self> {
        let cloud = Arc::new(FolderRevisionCloudService {
            token: token.to_string(),
        });
        let folder = Arc::new(RwLock::new(rev_manager.load::<FolderRevisionSerde>(Some(cloud)).await?));
        let rev_manager = Arc::new(rev_manager);

        #[cfg(feature = "sync")]
        let ws_manager = crate::services::web_socket::make_folder_ws_manager(
            user_id,
            folder_id.as_ref(),
            rev_manager.clone(),
            web_socket,
            folder.clone(),
        )
        .await;

        let user_id = user_id.to_owned();
        let folder_id = folder_id.to_owned();
        Ok(Self {
            user_id,
            folder_id,
            folder,
            rev_manager,
            #[cfg(feature = "sync")]
            ws_manager,
        })
    }

    #[cfg(feature = "sync")]
    pub async fn receive_ws_data(&self, data: ServerRevisionWSData) -> FlowyResult<()> {
        let _ = self.ws_manager.ws_passthrough_tx.send(data).await.map_err(|e| {
            let err_msg = format!("{} passthrough error: {}", self.folder_id, e);
            FlowyError::internal().context(err_msg)
        })?;

        Ok(())
    }

    #[cfg(not(feature = "sync"))]
    pub async fn receive_ws_data(&self, _data: ServerRevisionWSData) -> FlowyResult<()> {
        Ok(())
    }

    pub(crate) fn apply_change(&self, change: FolderChangeset) -> FlowyResult<()> {
        let FolderChangeset { operations: delta, md5 } = change;
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.json_bytes();
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

    #[allow(dead_code)]
    pub fn folder_json(&self) -> FlowyResult<String> {
        let json = self.folder.read().to_json()?;
        Ok(json)
    }
}

struct FolderRevisionSerde();
impl RevisionObjectDeserializer for FolderRevisionSerde {
    type Output = FolderPad;

    fn deserialize_revisions(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = FolderPad::from_revisions(revisions)?;
        Ok(pad)
    }
}

impl RevisionObjectSerializer for FolderRevisionSerde {
    fn serialize_revisions(revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let operations = make_operations_from_revisions::<EmptyAttributes>(revisions)?;
        Ok(operations.json_bytes())
    }
}

pub struct FolderRevisionCompactor();
impl RevisionCompress for FolderRevisionCompactor {
    fn serialize_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        FolderRevisionSerde::serialize_revisions(revisions)
    }
}

struct FolderRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for FolderRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

#[cfg(feature = "flowy_unit_test")]
impl FolderEditor {
    pub fn rev_manager(&self) -> Arc<RevisionManager> {
        self.rev_manager.clone()
    }
}
