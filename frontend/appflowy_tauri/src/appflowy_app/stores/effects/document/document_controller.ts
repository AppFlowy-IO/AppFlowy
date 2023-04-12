import { DocumentData, BlockType, TextDelta } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { DocumentBackendService } from './document_bd_svc';
import { Err } from 'ts-results';
import { BlockActionPB, BlockActionPayloadPB, BlockActionTypePB, BlockPB, FlowyError } from '@/services/backend';
import { DocumentObserver } from './document_observer';
import { nanoid } from 'nanoid';

export const DocumentControllerContext = createContext<DocumentController | null>(null);

export class DocumentController {
  private readonly backendService: DocumentBackendService;
  private readonly observer: DocumentObserver;

  constructor(public readonly viewId: string) {
    this.backendService = new DocumentBackendService(viewId);
    this.observer = new DocumentObserver(viewId);
  }

  open = async (): Promise<DocumentData | null> => {
    // example:
    await this.observer.subscribe({
      didReceiveUpdate: () => {
        console.log('didReceiveUpdate');
      },
    });

    const document = await this.backendService.openV2();
    let root_id = '';
    if (document.ok) {
      root_id = document.val.page_id;
      console.log(document.val.blocks);
    }
    await this.backendService.applyActions([
      BlockActionPB.fromObject({
        action: BlockActionTypePB.Insert,
        payload: BlockActionPayloadPB.fromObject({
          block: BlockPB.fromObject({
            id: nanoid(10),
            ty: 'text',
            parent_id: root_id,
          }),
        }),
      }),
    ]);

    const openDocumentResult = await this.backendService.open();
    if (openDocumentResult.ok) {
      return {
        rootId: '',
        blocks: {},
        ytexts: {},
        yarrays: {},
      };
    } else {
      return null;
    }
  };

  insert(
    node: {
      id: string;
      type: BlockType;
      delta?: TextDelta[];
    },
    parentId: string,
    prevId: string
  ) {
    //
  }

  transact(actions: (() => void)[]) {
    //
  }

  yTextApply = (yTextId: string, delta: TextDelta[]) => {
    //
  };

  dispose = async () => {
    await this.backendService.close();
  };
}
