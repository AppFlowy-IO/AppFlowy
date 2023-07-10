import { DocumentData, Node } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { DocumentBackendService } from './document_bd_svc';
import {
  BlockActionPB,
  DocEventPB,
  BlockActionTypePB,
  BlockEventPayloadPB,
  BlockPB,
  ChildrenPB,
} from '@/services/backend';
import { DocumentObserver } from './document_observer';
import * as Y from 'yjs';
import { get } from '@/appflowy_app/utils/tool';
import { blockPB2Node } from '$app/utils/document/block';
import { Log } from '$app/utils/log';
import { BLOCK_MAP_NAME, CHILDREN_MAP_NAME, META_NAME } from '$app/constants/document/name';

export class DocumentController {
  private readonly backendService: DocumentBackendService;
  private readonly observer: DocumentObserver;

  constructor(
    public readonly documentId: string,
    private onDocChange?: (props: { docId: string; isRemote: boolean; data: BlockEventPayloadPB }) => void
  ) {
    this.backendService = new DocumentBackendService(documentId);
    this.observer = new DocumentObserver(documentId);
  }

  open = async (): Promise<DocumentData> => {
    await this.observer.subscribe({
      didReceiveUpdate: this.updated,
    });

    const document = await this.backendService.open();

    if (document.ok) {
      const nodes: DocumentData['nodes'] = {};

      get<Map<string, BlockPB>>(document.val, [BLOCK_MAP_NAME]).forEach((block) => {
        Object.assign(nodes, {
          [block.id]: blockPB2Node(block),
        });
      });
      const children: Record<string, string[]> = {};

      get<Map<string, ChildrenPB>>(document.val, [META_NAME, CHILDREN_MAP_NAME]).forEach((child, key) => {
        children[key] = child.children;
      });
      return {
        rootId: document.val.page_id,
        nodes,
        children,
      };
    }

    return Promise.reject(document.val);
  };

  applyActions = async (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) => {
    Log.debug('applyActions', actions);
    if (actions.length === 0) return;
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

  getMoveChildrenAction = (children: Node[], parentId: string, prevId: string | null) => {
    return children.reverse().map((child) => {
      return this.getMoveAction(child, parentId, prevId);
    });
  };

  getDeleteAction = (node: Node) => {
    return {
      action: BlockActionTypePB.Delete,
      payload: this.getActionPayloadByNode(node, ''),
    };
  };

  canUndo = async () => {
    const result = await this.backendService.canUndoRedo();

    return result.ok && result.val.can_undo;
  };

  canRedo = async () => {
    const result = await this.backendService.canUndoRedo();

    return result.ok && result.val.can_redo;
  };

  undo = async () => {
    const result = await this.backendService.undo();

    return result.ok && result.val.is_success;
  };

  redo = async () => {
    const result = await this.backendService.redo();

    return result.ok && result.val.is_success;
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

    Log.debug('DocumentController', 'updated', { events, is_remote });
    events.forEach((blockEvent) => {
      blockEvent.event.forEach((_payload) => {
        this.onDocChange?.({
          docId: this.documentId,
          isRemote: is_remote,
          data: _payload,
        });
      });
    });
  };
}

export const DocumentControllerContext = createContext<DocumentController>(new DocumentController(''));
