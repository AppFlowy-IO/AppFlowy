import { DocumentData, BlockType } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { DocumentBackendService } from './document_bd_svc';
import { FlowyError, BlockActionPB, DocEventPB, BlockActionTypePB, BlockEventPayloadPB } from '@/services/backend';
import { DocumentObserver } from './document_observer';
import { Node } from '@/appflowy_app/stores/reducers/document/slice';
import * as Y from 'yjs';

export const DocumentControllerContext = createContext<DocumentController | null>(null);

export class DocumentController {
  private readonly backendService: DocumentBackendService;
  private readonly observer: DocumentObserver;

  constructor(
    public readonly viewId: string,
    private onDocChange?: (props: { isRemote: boolean; data: BlockEventPayloadPB }) => void
  ) {
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

  getInsertAction = (node: Node, prevId: string | null) => {
    // Here to make sure the delta is correct
    this.composeDelta(node);
    return {
      action: BlockActionTypePB.Insert,
      payload: this.getActionPayloadByNode(node, prevId),
    };
  };

  getUpdateAction = (node: Node) => {
    // Here to make sure the delta is correct
    this.composeDelta(node);
    return {
      action: BlockActionTypePB.Update,
      payload: this.getActionPayloadByNode(node, ''),
    };
  };

  getMoveAction = (node: Node, parentId: string, prevId: string | null) => {
    return {
      action: BlockActionTypePB.Move,
      payload: this.getActionPayloadByNode(
        {
          ...node,
          parent: parentId,
        },
        prevId
      ),
    };
  };

  getDeleteAction = (node: Node) => {
    return {
      action: BlockActionTypePB.Delete,
      payload: this.getActionPayloadByNode(node, ''),
    };
  };

  dispose = async () => {
    this.onDocChange = undefined;
    await this.backendService.close();
  };

  private getActionPayloadByNode = (node: Node, prevId: string | null) => {
    return {
      block: this.getBlockByNode(node),
      parent_id: node.parent || '',
      prev_id: prevId || '',
    };
  };

  private getBlockByNode = (node: Node) => {
    return {
      id: node.id,
      parent_id: node.parent || '',
      children_id: node.children,
      data: JSON.stringify(node.data),
      ty: node.type,
    };
  };

  private composeDelta = (node: Node) => {
    const delta = node.data.delta;
    if (!delta) {
      return;
    }
    // we use yjs to compose delta, it can make sure the delta is correct
    // for example, if we insert a text at the end of the line, the delta will be [{ insert: 'hello' }, { insert: " world" }]
    // but if we use yjs to compose the delta, the delta will be [{ insert: 'hello world' }]
    const ydoc = new Y.Doc();
    const ytext = ydoc.getText(node.id);
    ytext.applyDelta(delta);
    Object.assign(node.data, { delta: ytext.toDelta() });
  };

  private updated = (payload: Uint8Array) => {
    if (!this.onDocChange) return;
    const { events, is_remote } = DocEventPB.deserializeBinary(payload);

    events.forEach((event) => {
      event.event.forEach((_payload) => {
        this.onDocChange?.({
          isRemote: is_remote,
          data: _payload,
        });
      });
    });
  };
}
