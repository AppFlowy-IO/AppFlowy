use std::sync::Arc;
use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;

use crate::{
  event_handler::{apply_action_handler, close_document_handler, open_document_handler, create_document_handler },
  manager::DocumentManager,
};

pub fn init(document_manager: Arc<DocumentManager>) -> AFPlugin {
  let mut plugin = AFPlugin::new()
    .name(env!("CARGO_PKG_NAME"))
    .state(document_manager);

  plugin = plugin.event(DocumentEvent2::OpenDocument, open_document_handler);
  plugin = plugin.event(DocumentEvent2::CloseDocument, close_document_handler);
  plugin = plugin.event(DocumentEvent2::ApplyAction, apply_action_handler);
  plugin = plugin.event(DocumentEvent2::CreateDocument, create_document_handler);

  plugin
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Display, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum DocumentEvent2 {
  #[event(input = "OpenDocumentPayloadPBV2", output = "DocumentDataPB2")]
  OpenDocument = 0,

  #[event(input = "CloseDocumentPayloadPBV2")]
  CloseDocument = 1,

  #[event(input = "ApplyActionPayloadPBV2")]
  ApplyAction = 2,

  #[event(input = "CreateDocumentPayloadPBV2")]
  CreateDocument = 3,
}
