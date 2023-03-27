import { DocumentData, BlockType, TextDelta } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { DocumentBackendService } from './document_bd_svc';
import { Err } from 'ts-results';
import { FlowyError } from '@/services/backend';

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
        ytexts: {},
        yarrays: {}
      };
    } else {
      return null;
    }
  };


  insert(node: {
    id: string,
    type: BlockType,
    delta?: TextDelta[]
  }, parentId: string, prevId: string) {
    //
  }

  transact(actions: (() => void)[]) {
    //
  }

  yTextApply = (yTextId: string, delta: TextDelta[]) => {
    //
  }

  dispose = async () => {
    await this.backendService.close();
  };
}
