import {
  FlowyError,
  DocumentDataPB,
  OpenDocumentPayloadPB,
  ApplyActionPayloadPB,
  BlockActionPB,
  CloseDocumentPayloadPB,
  DocumentRedoUndoPayloadPB,
  DocumentRedoUndoResponsePB,
  TextDeltaPayloadPB,
} from '@/services/backend';
import { Result } from 'ts-results';
import {
  DocumentEventApplyAction,
  DocumentEventCloseDocument,
  DocumentEventOpenDocument,
  DocumentEventCanUndoRedo,
  DocumentEventRedo,
  DocumentEventUndo,
  DocumentEventCreateText,
  DocumentEventApplyTextDeltaEvent,
} from '@/services/backend/events/flowy-document2';

export class DocumentBackendService {
  constructor(public readonly viewId: string) {}

  open = (): Promise<Result<DocumentDataPB, FlowyError>> => {
    const payload = OpenDocumentPayloadPB.fromObject({
      document_id: this.viewId,
    });

    return DocumentEventOpenDocument(payload);
  };

  applyActions = (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]): Promise<Result<void, FlowyError>> => {
    const payload = ApplyActionPayloadPB.fromObject({
      document_id: this.viewId,
      actions: actions,
    });

    return DocumentEventApplyAction(payload);
  };

  createText = (textId: string, defaultDelta?: string): Promise<Result<void, FlowyError>> => {
    const payload = TextDeltaPayloadPB.fromObject({
      document_id: this.viewId,
      text_id: textId,
      delta: defaultDelta,
    });

    return DocumentEventCreateText(payload);
  };

  applyTextDelta = (textId: string, delta: string): Promise<Result<void, FlowyError>> => {
    const payload = TextDeltaPayloadPB.fromObject({
      document_id: this.viewId,
      text_id: textId,
      delta: delta,
    });

    return DocumentEventApplyTextDeltaEvent(payload);
  };

  close = (): Promise<Result<void, FlowyError>> => {
    const payload = CloseDocumentPayloadPB.fromObject({
      document_id: this.viewId,
    });

    return DocumentEventCloseDocument(payload);
  };

  canUndoRedo = (): Promise<Result<DocumentRedoUndoResponsePB, FlowyError>> => {
    const payload = DocumentRedoUndoPayloadPB.fromObject({
      document_id: this.viewId,
    });

    return DocumentEventCanUndoRedo(payload);
  };

  undo = (): Promise<Result<DocumentRedoUndoResponsePB, FlowyError>> => {
    const payload = DocumentRedoUndoPayloadPB.fromObject({
      document_id: this.viewId,
    });

    return DocumentEventUndo(payload);
  };

  redo = (): Promise<Result<DocumentRedoUndoResponsePB, FlowyError>> => {
    const payload = DocumentRedoUndoPayloadPB.fromObject({
      document_id: this.viewId,
    });

    return DocumentEventRedo(payload);
  };
}
