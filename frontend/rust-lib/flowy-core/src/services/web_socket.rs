use crate::services::persistence::FOLDER_ID;
use bytes::Bytes;
use flowy_collaboration::{
    entities::{
        revision::RevisionRange,
        ws_data::{ClientRevisionWSData, NewDocumentUser, ServerRevisionWSDataType},
    },
    folder::FolderPad,
};
use flowy_error::FlowyError;
use flowy_sync::{
    CompositeWSSinkDataProvider,
    RevisionManager,
    RevisionWSSinkDataProvider,
    RevisionWSSteamConsumer,
    RevisionWebSocket,
    RevisionWebSocketManager,
};
use lib_infra::future::FutureResult;
use parking_lot::RwLock;
use std::{sync::Arc, time::Duration};

pub(crate) async fn make_folder_ws_manager(
    rev_manager: Arc<RevisionManager>,
    web_socket: Arc<dyn RevisionWebSocket>,
    folder_pad: Arc<RwLock<FolderPad>>,
) -> Arc<RevisionWebSocketManager> {
    let object_id = FOLDER_ID;
    let composite_sink_provider = Arc::new(CompositeWSSinkDataProvider::new(object_id, rev_manager.clone()));
    let ws_stream_consumer = Arc::new(FolderWSStreamConsumerAdapter {
        object_id: object_id.to_string(),
        folder_pad,
        rev_manager,
        sink_provider: composite_sink_provider.clone(),
    });
    let sink_provider = Arc::new(FolderWSSinkDataProviderAdapter(composite_sink_provider));
    let ping_duration = Duration::from_millis(2000);
    Arc::new(RevisionWebSocketManager::new(
        object_id,
        web_socket,
        sink_provider,
        ws_stream_consumer,
        ping_duration,
    ))
}

pub(crate) struct FolderWSSinkDataProviderAdapter(Arc<CompositeWSSinkDataProvider>);
impl RevisionWSSinkDataProvider for FolderWSSinkDataProviderAdapter {
    fn next(&self) -> FutureResult<Option<ClientRevisionWSData>, FlowyError> {
        let sink_provider = self.0.clone();
        FutureResult::new(async move { sink_provider.next().await })
    }
}

struct FolderWSStreamConsumerAdapter {
    object_id: String,
    folder_pad: Arc<RwLock<FolderPad>>,
    rev_manager: Arc<RevisionManager>,
    sink_provider: Arc<CompositeWSSinkDataProvider>,
}

impl RevisionWSSteamConsumer for FolderWSStreamConsumerAdapter {
    fn receive_push_revision(&self, bytes: Bytes) -> FutureResult<(), FlowyError> { todo!() }

    fn receive_ack(&self, id: String, ty: ServerRevisionWSDataType) -> FutureResult<(), FlowyError> {
        let sink_provider = self.sink_provider.clone();
        FutureResult::new(async move { sink_provider.ack_data(id, ty).await })
    }

    fn receive_new_user_connect(&self, _new_user: NewDocumentUser) -> FutureResult<(), FlowyError> {
        FutureResult::new(async move { Ok(()) })
    }

    fn pull_revisions_in_range(&self, range: RevisionRange) -> FutureResult<(), FlowyError> {
        let rev_manager = self.rev_manager.clone();
        let sink_provider = self.sink_provider.clone();
        let object_id = self.object_id.clone();
        FutureResult::new(async move {
            let revisions = rev_manager.get_revisions_in_range(range).await?;
            let data = ClientRevisionWSData::from_revisions(&object_id, revisions);
            sink_provider.push_data(data).await;
            Ok(())
        })
    }
}
