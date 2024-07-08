use std::sync::Weak;

use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;
use tracing::event;

use crate::event_handler::get_snapshot_meta_handler;
use crate::{event_handler::*, manager::DocumentManager};

pub fn init(document_manager: Weak<DocumentManager>) -> AFPlugin {
  AFPlugin::new()
    .name(env!("CARGO_PKG_NAME"))
    .state(document_manager)
    .event(DocumentEvent::CreateDocument, create_document_handler)
    .event(DocumentEvent::OpenDocument, open_document_handler)
    .event(DocumentEvent::CloseDocument, close_document_handler)
    .event(DocumentEvent::ApplyAction, apply_action_handler)
    .event(DocumentEvent::GetDocumentData, get_document_data_handler)
    .event(
      DocumentEvent::GetDocEncodedCollab,
      get_encode_collab_handler,
    )
    .event(
      DocumentEvent::ConvertDataToDocument,
      convert_data_to_document,
    )
    .event(DocumentEvent::Redo, redo_handler)
    .event(DocumentEvent::Undo, undo_handler)
    .event(DocumentEvent::CanUndoRedo, can_undo_redo_handler)
    .event(
      DocumentEvent::GetDocumentSnapshotMeta,
      get_snapshot_meta_handler,
    )
    .event(
      DocumentEvent::GetDocumentSnapshot,
      get_snapshot_data_handler,
    )
    .event(DocumentEvent::CreateText, create_text_handler)
    .event(DocumentEvent::ApplyTextDeltaEvent, apply_text_delta_handler)
    .event(DocumentEvent::ConvertDocument, convert_document_handler)
    .event(
      DocumentEvent::ConvertDataToJSON,
      convert_data_to_json_handler,
    )
    .event(DocumentEvent::UploadFile, upload_file_handler)
    .event(DocumentEvent::DownloadFile, download_file_handler)
    .event(DocumentEvent::DeleteFile, delete_file_handler)
    .event(
      DocumentEvent::SetAwarenessState,
      set_awareness_local_state_handler,
    )
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

  #[event(input = "OpenDocumentPayloadPB", output = "DocumentDataPB")]
  GetDocumentData = 4,

  #[event(input = "ConvertDataPayloadPB", output = "DocumentDataPB")]
  ConvertDataToDocument = 5,

  #[event(
    input = "DocumentRedoUndoPayloadPB",
    output = "DocumentRedoUndoResponsePB"
  )]
  Redo = 6,

  #[event(
    input = "DocumentRedoUndoPayloadPB",
    output = "DocumentRedoUndoResponsePB"
  )]
  Undo = 7,

  #[event(
    input = "DocumentRedoUndoPayloadPB",
    output = "DocumentRedoUndoResponsePB"
  )]
  CanUndoRedo = 8,

  #[event(
    input = "OpenDocumentPayloadPB",
    output = "RepeatedDocumentSnapshotMetaPB"
  )]
  GetDocumentSnapshotMeta = 9,

  #[event(input = "TextDeltaPayloadPB")]
  CreateText = 10,

  #[event(input = "TextDeltaPayloadPB")]
  ApplyTextDeltaEvent = 11,

  // document in event_handler.rs -> convert_document
  #[event(
    input = "ConvertDocumentPayloadPB",
    output = "ConvertDocumentResponsePB"
  )]
  ConvertDocument = 12,

  // document in event_handler.rs -> convert_data_to_json
  #[event(
    input = "ConvertDataToJsonPayloadPB",
    output = "ConvertDataToJsonResponsePB"
  )]
  ConvertDataToJSON = 13,

  #[event(input = "DocumentSnapshotMetaPB", output = "DocumentSnapshotPB")]
  GetDocumentSnapshot = 14,

  #[event(input = "UploadFileParamsPB", output = "UploadedFilePB")]
  UploadFile = 15,
  #[event(input = "UploadedFilePB")]
  DownloadFile = 16,
  #[event(input = "UploadedFilePB")]
  DeleteFile = 17,

  #[event(input = "UpdateDocumentAwarenessStatePB")]
  SetAwarenessState = 18,

  #[event(input = "OpenDocumentPayloadPB", output = "EncodedCollabPB")]
  GetDocEncodedCollab = 19,
}
