import { DocumentData, BlockType } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { DocumentBackendService } from './document_bd_svc';
import { FlowyError } from '@/services/backend';
import { DocumentObserver } from './document_observer';

export const DocumentControllerContext = createContext<DocumentController | null>(null);

export class DocumentController {
  private readonly backendService: DocumentBackendService;
  private readonly observer: DocumentObserver;

  constructor(public readonly viewId: string) {
    this.backendService = new DocumentBackendService(viewId);
    this.observer = new DocumentObserver(viewId);
  }

  open = async (): Promise<DocumentData | FlowyError> => {
    // example:
    await this.observer.subscribe({
      didReceiveUpdate: () => {
        console.log('didReceiveUpdate');
      },
    });

    const document = await this.backendService.open();
    if (document.ok) {
      console.log(document.val);
      const blocks: DocumentData["blocks"] = {};
      document.val.blocks.forEach((block) => {
        blocks[block.id] = {
          id: block.id,
          type: block.ty as BlockType,
          parent: block.parent_id,
          children: block.children_id,
          data: JSON.parse(block.data),
        };
      });
      const childrenMap: Record<string, string[]> = {};
      document.val.meta.children_map.forEach((child, key) => { childrenMap[key] = child.children; });
      return {
        rootId: document.val.page_id,
        blocks,
        meta: {
          childrenMap
        }
      }
    }
    return document.val;

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
