import { DocumentData, BlockType } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { DocumentBackendService } from './document_bd_svc';
import { FlowyError, BlockActionPB } from '@/services/backend';
import { DocumentObserver } from './document_observer';

export const DocumentControllerContext = createContext<DocumentController | null>(null);

export class DocumentController {
  private readonly backendService: DocumentBackendService;
  private readonly observer: DocumentObserver;

  constructor(public readonly viewId: string) {
    this.backendService = new DocumentBackendService(viewId);
    this.observer = new DocumentObserver(viewId);
  }

  create = async (): Promise<FlowyError | void> => {
    const result = await this.backendService.create();
    if (result.ok) {
      return;
    }
    return result.val;
  };
  open = async (): Promise<DocumentData> => {
    await this.observer.subscribe({
      didReceiveUpdate: this.updated,
    });

    const document = await this.backendService.open();
    if (document.ok) {
      const blocks: DocumentData['blocks'] = {};
      document.val.blocks.forEach((block) => {
        let data = {};
        try {
          data = JSON.parse(block.data);
        } catch {
          console.log('json parse error', block.data);
        }

        blocks[block.id] = {
          id: block.id,
          type: block.ty as BlockType,
          parent: block.parent_id,
          children: block.children_id,
          data,
        };
      });
      const childrenMap: Record<string, string[]> = {};
      document.val.meta.children_map.forEach((child, key) => {
        childrenMap[key] = child.children;
      });
      return {
        rootId: document.val.page_id,
        blocks,
        meta: {
          childrenMap,
        },
      };
    }

    return Promise.reject(document.val);
  };

  applyActions = async (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) => {
    await this.backendService.applyActions(actions);
  };

  dispose = async () => {
    await this.backendService.close();
  };

  private updated = (payload: Uint8Array) => {
    console.log('didReceiveUpdate', payload);
  };
}
