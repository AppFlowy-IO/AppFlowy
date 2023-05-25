import {
  FlowyError,
  DocumentDataPB,
  OpenDocumentPayloadPB,
  CreateDocumentPayloadPB,
  ApplyActionPayloadPB,
  BlockActionPB,
  CloseDocumentPayloadPB,
} from '@/services/backend';
import { Result } from 'ts-results';
import {
  DocumentEventApplyAction,
  DocumentEventCloseDocument,
  DocumentEventOpenDocument,
  DocumentEventCreateDocument,
} from '@/services/backend/events/flowy-document2';

export class DocumentBackendService {
  constructor(public readonly viewId: string) {}

  create = (): Promise<Result<void, FlowyError>> => {
    const payload = CreateDocumentPayloadPB.fromObject({
      document_id: this.viewId,
    });
    return DocumentEventCreateDocument(payload);
  };

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
}
