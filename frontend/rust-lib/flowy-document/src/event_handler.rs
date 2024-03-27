/*
 * The following code defines functions that handle creating, opening, and closing documents,
 * as well as performing actions on documents. These functions make use of a DocumentManager,
 * which you can think of as a higher-level interface to interact with documents.
 */

use std::sync::{Arc, Weak};

use collab_document::blocks::{
  BlockAction, BlockActionPayload, BlockActionType, BlockEvent, BlockEventPayload, DeltaType,
  DocumentData,
};

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use tracing::instrument;

use crate::entities::*;
use crate::parser::document_data_parser::DocumentDataParser;
use crate::parser::external::parser::ExternalDataToNestedJSONParser;
use crate::parser::parser_entities::{
  ConvertDataToJsonParams, ConvertDataToJsonPayloadPB, ConvertDataToJsonResponsePB,
  ConvertDocumentParams, ConvertDocumentPayloadPB, ConvertDocumentResponsePB,
};
use crate::{manager::DocumentManager, parser::json::parser::JsonToDocumentParser};

fn upgrade_document(
  document_manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<Arc<DocumentManager>> {
  let manager = document_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The document manager is already dropped"))?;
  Ok(manager)
}

// Handler for creating a new document
pub(crate) async fn create_document_handler(
  data: AFPluginData<CreateDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: CreateDocumentParams = data.into_inner().try_into()?;
  let uid = manager.user_service.user_id()?;
  manager
    .create_document(uid, &params.document_id, params.initial_data)
    .await?;
  Ok(())
}

// Handler for opening an existing document
#[instrument(level = "debug", skip_all, err)]
pub(crate) async fn open_document_handler(
  data: AFPluginData<OpenDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentDataPB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: OpenDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document_data = document.lock().get_document_data()?;
  data_result_ok(DocumentDataPB::from(document_data))
}

pub(crate) async fn close_document_handler(
  data: AFPluginData<CloseDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: CloseDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  manager.close_document(&doc_id).await?;
  Ok(())
}

// Get the content of the existing document,
//  if the document does not exist, return an error.
pub(crate) async fn get_document_data_handler(
  data: AFPluginData<OpenDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentDataPB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: OpenDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document_data = manager.get_document_data(&doc_id).await?;
  data_result_ok(DocumentDataPB::from(document_data))
}

// Handler for applying an action to a document
pub(crate) async fn apply_action_handler(
  data: AFPluginData<ApplyActionPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: ApplyActionParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let actions = params.actions;
  document.lock().apply_action(actions);
  Ok(())
}

/// Handler for creating a text
pub(crate) async fn create_text_handler(
  data: AFPluginData<TextDeltaPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: TextDeltaParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  document.create_text(&params.text_id, params.delta);
  Ok(())
}

/// Handler for applying delta to a text
pub(crate) async fn apply_text_delta_handler(
  data: AFPluginData<TextDeltaPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let params: TextDeltaParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let text_id = params.text_id;
  let delta = params.delta;
  let document = document.lock();
  document.apply_text_delta(&text_id, delta);
  Ok(())
}

pub(crate) async fn convert_data_to_document(
  data: AFPluginData<ConvertDataPayloadPB>,
) -> DataResult<DocumentDataPB, FlowyError> {
  let payload = data.into_inner();
  let document = convert_data_to_document_internal(payload)?;
  data_result_ok(document)
}

pub fn convert_data_to_document_internal(
  payload: ConvertDataPayloadPB,
) -> Result<DocumentDataPB, FlowyError> {
  let params: ConvertDataParams = payload.try_into()?;
  let convert_type = params.convert_type;
  let data = params.data;
  match convert_type {
    ConvertType::Json => {
      let json_str = String::from_utf8(data).map_err(|_| FlowyError::invalid_data())?;
      let document = JsonToDocumentParser::json_str_to_document(&json_str)?;
      Ok(document)
    },
  }
}

pub(crate) async fn redo_handler(
  data: AFPluginData<DocumentRedoUndoPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentRedoUndoResponsePB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: DocumentRedoUndoParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  let redo = document.redo();
  let can_redo = document.can_redo();
  let can_undo = document.can_undo();
  data_result_ok(DocumentRedoUndoResponsePB {
    can_redo,
    can_undo,
    is_success: redo,
  })
}

pub(crate) async fn undo_handler(
  data: AFPluginData<DocumentRedoUndoPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentRedoUndoResponsePB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: DocumentRedoUndoParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  let undo = document.undo();
  let can_redo = document.can_redo();
  let can_undo = document.can_undo();
  data_result_ok(DocumentRedoUndoResponsePB {
    can_redo,
    can_undo,
    is_success: undo,
  })
}

pub(crate) async fn can_undo_redo_handler(
  data: AFPluginData<DocumentRedoUndoPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentRedoUndoResponsePB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: DocumentRedoUndoParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let document = manager.get_document(&doc_id).await?;
  let document = document.lock();
  let can_redo = document.can_redo();
  let can_undo = document.can_undo();
  drop(document);
  data_result_ok(DocumentRedoUndoResponsePB {
    can_redo,
    can_undo,
    is_success: true,
  })
}

pub(crate) async fn get_snapshot_meta_handler(
  data: AFPluginData<OpenDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<RepeatedDocumentSnapshotMetaPB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: OpenDocumentParams = data.into_inner().try_into()?;
  let doc_id = params.document_id;
  let snapshots = manager.get_document_snapshot_meta(&doc_id, 10).await?;
  data_result_ok(RepeatedDocumentSnapshotMetaPB { items: snapshots })
}

pub(crate) async fn get_snapshot_data_handler(
  data: AFPluginData<DocumentSnapshotMetaPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<DocumentSnapshotPB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params = data.into_inner();
  let snapshot = manager.get_document_snapshot(&params.snapshot_id).await?;
  data_result_ok(snapshot)
}

impl From<BlockActionPB> for BlockAction {
  fn from(pb: BlockActionPB) -> Self {
    Self {
      action: pb.action.into(),
      payload: pb.payload.into(),
    }
  }
}

impl From<BlockActionTypePB> for BlockActionType {
  fn from(pb: BlockActionTypePB) -> Self {
    match pb {
      BlockActionTypePB::Insert => Self::Insert,
      BlockActionTypePB::Update => Self::Update,
      BlockActionTypePB::Delete => Self::Delete,
      BlockActionTypePB::Move => Self::Move,
      BlockActionTypePB::InsertText => Self::InsertText,
      BlockActionTypePB::ApplyTextDelta => Self::ApplyTextDelta,
    }
  }
}

impl From<BlockActionPayloadPB> for BlockActionPayload {
  fn from(pb: BlockActionPayloadPB) -> Self {
    Self {
      block: pb.block.map(|b| b.into()),
      parent_id: pb.parent_id,
      prev_id: pb.prev_id,
      text_id: pb.text_id,
      delta: pb.delta,
    }
  }
}

impl From<BlockEvent> for BlockEventPB {
  fn from(payload: BlockEvent) -> Self {
    // Convert each individual `BlockEvent` to a protobuf `BlockEventPB`, and collect the results into a `Vec`
    Self {
      event: payload.iter().map(|e| e.to_owned().into()).collect(),
    }
  }
}

impl From<BlockEventPayload> for BlockEventPayloadPB {
  fn from(payload: BlockEventPayload) -> Self {
    Self {
      command: payload.command.into(),
      path: payload.path,
      id: payload.id,
      value: payload.value,
    }
  }
}

impl From<DeltaType> for DeltaTypePB {
  fn from(action: DeltaType) -> Self {
    match action {
      DeltaType::Inserted => Self::Inserted,
      DeltaType::Updated => Self::Updated,
      DeltaType::Removed => Self::Removed,
    }
  }
}

impl From<(&Vec<BlockEvent>, bool, Option<DocumentData>)> for DocEventPB {
  fn from(
    (events, is_remote, new_snapshot): (&Vec<BlockEvent>, bool, Option<DocumentData>),
  ) -> Self {
    // Convert each individual `BlockEvent` to a protobuf `BlockEventPB`, and collect the results into a `Vec`
    Self {
      events: events.iter().map(|e| e.to_owned().into()).collect(),
      is_remote,
      new_snapshot: new_snapshot.map(|d| d.into()),
    }
  }
}

/// Handler for converting a document to a JSON string, HTML string, or plain text string.
///
/// ConvertDocumentPayloadPB is the input of this event.
/// ConvertDocumentResponsePB is the output of this event.
///
/// # Examples
///
/// Basic usage:
///
/// ```txt
/// // document: [{ "block_id": "1", "type": "paragraph", "data": {"delta": [{ "insert": "Hello World!" }] } }, { "block_id": "2", "type": "paragraph", "data": {"delta": [{ "insert": "Hello World!" }] }
/// let test = DocumentEventTest::new().await;
/// let view = test.create_document().await;
/// let payload = ConvertDocumentPayloadPB {
///   document_id: view.id,
///   range: Some(RangePB {
///     start: SelectionPB {
///       block_id: "1".to_string(),
///       index: 0,
///       length: 5,
///     },
///     end: SelectionPB {
///       block_id: "2".to_string(),
///       index: 5,
///       length: 7,
///     }
///   }),
///   parse_types: ParseTypePB {
///     json: true,
///     text: true,
///     html: true,
///   },
/// };
/// let result = test.convert_document(payload).await;
/// assert_eq!(result.json, Some("[{ \"block_id\": \"1\", \"type\": \"paragraph\", \"data\": {\"delta\": [{ \"insert\": \"Hello\" }] } }, { \"block_id\": \"2\", \"type\": \"paragraph\", \"data\": {\"delta\": [{ \"insert\": \" World!\" }] } }".to_string()));
/// assert_eq!(result.text, Some("Hello\n World!".to_string()));
/// assert_eq!(result.html, Some("<p>Hello</p><p> World!</p>".to_string()));
/// ```
/// #
pub async fn convert_document_handler(
  data: AFPluginData<ConvertDocumentPayloadPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<ConvertDocumentResponsePB, FlowyError> {
  let manager = upgrade_document(manager)?;
  let params: ConvertDocumentParams = data.into_inner().try_into()?;

  let document = manager.get_document(&params.document_id).await?;
  let document_data = document.lock().get_document_data()?;
  let parser = DocumentDataParser::new(Arc::new(document_data), params.range);

  if !params.parse_types.any_enabled() {
    return data_result_ok(ConvertDocumentResponsePB::default());
  }

  let root = &parser.to_json();

  data_result_ok(ConvertDocumentResponsePB {
    json: params
      .parse_types
      .json
      .then(|| serde_json::to_string(root).unwrap_or_default()),
    html: params
      .parse_types
      .html
      .then(|| parser.to_html_with_json(root)),
    text: params
      .parse_types
      .text
      .then(|| parser.to_text_with_json(root)),
  })
}

/// Handler for converting a string to a JSON string.
/// # Examples
/// Basic usage:
/// ```txt
/// let test = DocumentEventTest::new().await;
/// let payload = ConvertDataToJsonPayloadPB {
///  data: "<p>Hello</p><p> World!</p>".to_string(),
///  input_type: InputTypePB::Html,
/// };
/// let result: ConvertDataToJsonResponsePB = test.convert_data_to_json(payload).await;
/// let expect_json = json!({ "type": "page", "data": {}, "children": [{ "type": "paragraph", "children": [], "data": { "delta": [{ "insert": "Hello" }] } }, { "type": "paragraph", "children": [], "data": { "delta": [{ "insert": " World!" }] } }] });
/// assert!(serde_json::from_str::<NestedBlock>(&result.json).unwrap().eq(&serde_json::from_value::<NestedBlock>(expect_json).unwrap()));
/// ```
pub(crate) async fn convert_data_to_json_handler(
  data: AFPluginData<ConvertDataToJsonPayloadPB>,
) -> DataResult<ConvertDataToJsonResponsePB, FlowyError> {
  let payload: ConvertDataToJsonParams = data.try_into_inner()?.try_into()?;
  let parser = ExternalDataToNestedJSONParser::new(payload.data, payload.input_type);

  let result = match parser.to_nested_block() {
    Some(result) => serde_json::to_string(&result)?,
    None => "".to_string(),
  };

  data_result_ok(ConvertDataToJsonResponsePB { json: result })
}

// Handler for uploading a file
// `workspace_id` and `file_name` determines file identity
pub(crate) async fn upload_file_handler(
  params: AFPluginData<UploadFileParamsPB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> DataResult<UploadedFilePB, FlowyError> {
  let AFPluginData(UploadFileParamsPB {
    workspace_id,
    local_file_path,
    is_async,
  }) = params;

  let manager = upgrade_document(manager)?;
  let url = manager
    .upload_file(workspace_id, &local_file_path, is_async)
    .await?;

  Ok(AFPluginData(UploadedFilePB {
    url,
    local_file_path,
  }))
}

#[instrument(level = "debug", skip_all, err)]
pub(crate) async fn download_file_handler(
  params: AFPluginData<UploadedFilePB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let AFPluginData(UploadedFilePB {
    url,
    local_file_path,
  }) = params;

  let manager = upgrade_document(manager)?;
  manager.download_file(local_file_path, url).await
}

// Handler for deleting file
pub(crate) async fn delete_file_handler(
  params: AFPluginData<UploadedFilePB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let AFPluginData(UploadedFilePB {
    url,
    local_file_path,
  }) = params;
  let manager = upgrade_document(manager)?;
  manager.delete_file(local_file_path, url).await
}

pub(crate) async fn set_awareness_local_state_handler(
  data: AFPluginData<UpdateDocumentAwarenessStatePB>,
  manager: AFPluginState<Weak<DocumentManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_document(manager)?;
  let data = data.into_inner();
  let doc_id = data.document_id.clone();
  manager
    .set_document_awareness_local_state(&doc_id, data)
    .await?;
  Ok(())
}
