import {
  FlowyError,
  DocumentDataPB2,
  OpenDocumentPayloadPBV2,
  CreateDocumentPayloadPBV2,
  ApplyActionPayloadPBV2,
  BlockActionPB,
  CloseDocumentPayloadPBV2,
} from '@/services/backend';
import { Result } from 'ts-results';
import {
  DocumentEvent2ApplyAction,
  DocumentEvent2CloseDocument,
  DocumentEvent2OpenDocument,
  DocumentEvent2CreateDocument,
} from '@/services/backend/events/flowy-document2';

export class DocumentBackendService {
  constructor(public readonly viewId: string) {}

  create = (): Promise<Result<void, FlowyError>> => {
    const payload = CreateDocumentPayloadPBV2.fromObject({
      document_id: this.viewId,
    });
    return DocumentEvent2CreateDocument(payload);
  };

  open = (): Promise<Result<DocumentDataPB2, FlowyError>> => {
    const payload = OpenDocumentPayloadPBV2.fromObject({
      document_id: this.viewId,
    });
    return DocumentEvent2OpenDocument(payload);
  };

  applyActions = (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]): Promise<Result<void, FlowyError>> => {
    const payload = ApplyActionPayloadPBV2.fromObject({
      document_id: this.viewId,
      actions: actions,
    });
    return DocumentEvent2ApplyAction(payload);
  };

  close = (): Promise<Result<void, FlowyError>> => {
    const payload = CloseDocumentPayloadPBV2.fromObject({
      document_id: this.viewId,
    });
    return DocumentEvent2CloseDocument(payload);
  };
}
