import { DocumentData, BlockType, TextDelta } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { DocumentBackendService } from './document_bd_svc';

export const DocumentControllerContext = createContext<DocumentController | null>(null);

export class DocumentController {
  private readonly backendService: DocumentBackendService;

  constructor(public readonly viewId: string) {
    this.backendService = new DocumentBackendService(viewId);
  }

  open = async (): Promise<DocumentData | null> => {
    const openDocumentResult = await this.backendService.open();
    if (openDocumentResult.ok) {
      return {
        rootId: '',
        blocks: {},
        meta: {
          childrenMap: {},
        },
      };
    } else {
      return null;
    }
  };

  applyActions = (
    actions: {
      type: string;
      payload: any;
    }[]
  ) => {
    //
  };

  dispose = async () => {
    await this.backendService.close();
  };
}
