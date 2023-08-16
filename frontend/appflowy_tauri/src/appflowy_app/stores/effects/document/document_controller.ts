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
import { get } from '@/appflowy_app/utils/tool';
import { blockPB2Node } from '$app/utils/document/block';
import { Log } from '$app/utils/log';
import { BLOCK_MAP_NAME, CHILDREN_MAP_NAME, META_NAME, TEXT_MAP_NAME } from '$app/constants/document/name';

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

  get backend() {
    return this.backendService;
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
      const deltaMap: Record<string, string> = {};

      get<Map<string, ChildrenPB>>(document.val, [META_NAME, CHILDREN_MAP_NAME]).forEach((child, key) => {
        children[key] = child.children;
      });

      get<Map<string, string>>(document.val, [META_NAME, TEXT_MAP_NAME]).forEach((delta, key) => {
        deltaMap[key] = delta;
      });
      return {
        rootId: document.val.page_id,
        nodes,
        children,
        deltaMap,
      };
    }

    return Promise.reject(document.val);
  };

  applyTextDelta = async (textId: string, delta: string) => {
    const result = await this.backendService.applyTextDelta(textId, delta);

    if (result.ok) {
      return;
    }

    return Promise.reject(result.err);
  };

  applyActions = async (actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) => {
    Log.debug('applyActions', actions);
    if (actions.length === 0) return;
    await this.backendService.applyActions(actions);
  };

  getInsertAction = (node: Node, prevId: string | null) => {
    return {
      action: BlockActionTypePB.Insert,
      payload: this.getActionPayloadByNode(node, prevId),
    };
  };

  getInsertTextActions = (node: Node, delta: string, prevId: string | null) => {
    const payload = this.getActionPayloadByNode(node, prevId);
    const textId = node.externalId;

    return [
      {
        action: BlockActionTypePB.InsertText,
        payload: {
          ...payload,
          text_id: textId,
          delta,
        },
      },
      this.getInsertAction(node, prevId),
    ];
  };

  getApplyTextDeltaAction = (node: Node, delta: string) => {
    const textId = node.externalId;
    const payload = this.getActionPayloadByNode(node, '');

    return {
      action: BlockActionTypePB.ApplyTextDelta,
      payload: {
        ...payload,
        text_id: textId,
        delta,
      },
    };
  };

  getUpdateAction = (node: Node) => {
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
      external_id: node.externalId,
      external_type: node.externalType,
    };
  };

  private updated = (payload: Uint8Array) => {
    if (!this.onDocChange) return;
    const { events, is_remote } = DocEventPB.deserializeBinary(payload);

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
