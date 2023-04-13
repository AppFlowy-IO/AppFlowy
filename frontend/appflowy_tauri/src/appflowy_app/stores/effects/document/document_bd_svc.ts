import {
  DocumentDataPB,
  DocumentVersionPB,
  EditPayloadPB,
  FlowyError,
  OpenDocumentPayloadPB,
  DocumentDataPB2,
  ViewIdPB,
  OpenDocumentPayloadPBV2,
  ApplyActionPayloadPBV2,
  BlockActionTypePB,
  BlockActionPB,
  CloseDocumentPayloadPBV2,
} from '@/services/backend';
import { DocumentEventApplyEdit, DocumentEventGetDocument } from '@/services/backend/events/flowy-document';
import { Result } from 'ts-results';
import { FolderEventCloseView } from '@/services/backend/events/flowy-folder2';
import {
  DocumentEvent2ApplyAction,
  DocumentEvent2CloseDocument,
  DocumentEvent2OpenDocument,
} from '@/services/backend/events/flowy-document2';

export class DocumentBackendService {
  constructor(public readonly viewId: string) {}

  open = (): Promise<Result<DocumentDataPB2, FlowyError>> => {
    const payload = OpenDocumentPayloadPBV2.fromObject({
      document_id: this.viewId,
    });
    return DocumentEvent2OpenDocument(payload);
  };

  applyActions = (actions: [BlockActionPB]): Promise<Result<void, FlowyError>> => {
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
