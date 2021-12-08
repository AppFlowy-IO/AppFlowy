use crate::{helper::ViewTest, FlowySDKTest};
use flowy_document::services::doc::edit::ClientDocEditor;
use flowy_document_infra::entities::doc::DocIdentifier;
use std::sync::Arc;
use tokio::time::Interval;

pub struct EditorTest {
    pub sdk: FlowySDKTest,
}

impl EditorTest {
    pub async fn new() -> Self {
        let sdk = FlowySDKTest::setup();
        let _ = sdk.init_user().await;
        Self { sdk }
    }

    pub async fn create_doc(&self) -> Arc<ClientDocEditor> {
        let test = ViewTest::new(&self.sdk).await;
        let doc_identifier: DocIdentifier = test.view.id.clone().into();
        self.sdk.flowy_document.open(doc_identifier).await.unwrap()
    }
}

pub enum EditAction {
    InsertText(&'static str, usize),
    Delete(Interval),
    Replace(Interval, &'static str),
    Undo(),
    Redo(),
    AssertJson(&'static str),
}
