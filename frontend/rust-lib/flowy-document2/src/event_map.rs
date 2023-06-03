use std::sync::Arc;
use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;

use crate::{
  event_handler::{
    apply_action_handler, close_document_handler, convert_data_to_document,
    create_document_handler, get_document_data_handler, open_document_handler,
  },
  manager::DocumentManager,
};

pub fn init(document_manager: Arc<DocumentManager>) -> AFPlugin {
  let mut plugin = AFPlugin::new()
    .name(env!("CARGO_PKG_NAME"))
    .state(document_manager);

  plugin = plugin.event(DocumentEvent::CreateDocument, create_document_handler);
  plugin = plugin.event(DocumentEvent::OpenDocument, open_document_handler);
  plugin = plugin.event(DocumentEvent::CloseDocument, close_document_handler);
  plugin = plugin.event(DocumentEvent::ApplyAction, apply_action_handler);
  plugin = plugin.event(DocumentEvent::GetDocumentData, get_document_data_handler);
  plugin = plugin.event(
    DocumentEvent::ConvertDataToDocument,
    convert_data_to_document,
  );

  plugin
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Display, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum DocumentEvent {
  #[event(input = "CreateDocumentPayloadPB")]
  CreateDocument = 0,

  #[event(input = "OpenDocumentPayloadPB", output = "DocumentDataPB")]
  OpenDocument = 1,

  #[event(input = "CloseDocumentPayloadPB")]
  CloseDocument = 2,

  #[event(input = "ApplyActionPayloadPB")]
  ApplyAction = 3,

  #[event(input = "GetDocumentDataPayloadPB")]
  GetDocumentData = 4,

  #[event(input = "ConvertDataPayloadPB", output = "DocumentDataPB")]
  ConvertDataToDocument = 5,
}
