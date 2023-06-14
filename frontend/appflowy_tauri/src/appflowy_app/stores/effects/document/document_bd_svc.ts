import {
  FlowyError,
  DocumentDataPB,
  OpenDocumentPayloadPB,
  CreateDocumentPayloadPB,
  ApplyActionPayloadPB,
  BlockActionPB,
  CloseDocumentPayloadPB,
  DocumentRedoUndoPayloadPB,
  DocumentRedoUndoResponsePB,
} from '@/services/backend';
import { Result } from 'ts-results';
import {
  DocumentEventApplyAction,
  DocumentEventCloseDocument,
  DocumentEventOpenDocument,
  DocumentEventCreateDocument,
  DocumentEventCanUndoRedo,
  DocumentEventRedo,
  DocumentEventUndo,
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
