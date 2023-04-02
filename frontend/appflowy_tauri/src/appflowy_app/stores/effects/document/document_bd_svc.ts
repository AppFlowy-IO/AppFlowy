import {
  DocumentDataPB,
  DocumentVersionPB,
  EditPayloadPB,
  FlowyError,
  OpenDocumentPayloadPB,
  ViewIdPB,
} from '@/services/backend';
import { DocumentEventApplyEdit, DocumentEventGetDocument } from '@/services/backend/events/flowy-document';
import { Result } from 'ts-results';
import { FolderEventCloseView } from '@/services/backend/events/flowy-folder';

export class DocumentBackendService {
  constructor(public readonly viewId: string) {}

  open = (): Promise<Result<DocumentDataPB, FlowyError>> => {
    const payload = OpenDocumentPayloadPB.fromObject({ document_id: this.viewId, version: DocumentVersionPB.V1 });
    return DocumentEventGetDocument(payload);
  };

  applyEdit = (operations: string) => {
    const payload = EditPayloadPB.fromObject({ doc_id: this.viewId, operations: operations });
    return DocumentEventApplyEdit(payload);
  };

  close = () => {
    const payload = ViewIdPB.fromObject({ value: this.viewId });
    return FolderEventCloseView(payload);
  };
}
