import { DocumentData, BlockType, DeltaItem } from '@/appflowy_app/interfaces/document';
import { createContext, Dispatch } from 'react';
import { DocumentBackendService } from './document_bd_svc';
import { FlowyError, BlockActionPB, DocEventPB, DeltaTypePB, BlockActionTypePB } from '@/services/backend';
import { DocumentObserver } from './document_observer';
import { documentActions, Node } from '@/appflowy_app/stores/reducers/document/slice';

export const DocumentControllerContext = createContext<DocumentController | null>(null);

export class DocumentController {
  private readonly backendService: DocumentBackendService;
  private readonly observer: DocumentObserver;

  constructor(public readonly viewId: string, private dispatch?: Dispatch<any>) {
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
    return {
      action: BlockActionTypePB.Insert,
      payload: this.getActionPayloadByNode(node, prevId),
    }
  }

  getUpdateAction = (node: Node) => {
    return {
      action: BlockActionTypePB.Update,
      payload: this.getActionPayloadByNode(node, ""),
    }
  }

  getMoveAction = (node: Node, parentId: string, prevId: string | null) => {
    node.parent = parentId;
    return {
      action: BlockActionTypePB.Move,
      payload: this.getActionPayloadByNode(node, prevId),
    }
  }

  getDeleteAction = (node: Node) => {
    return {
      action: BlockActionTypePB.Delete,
      payload: this.getActionPayloadByNode(node, ""),
    }
  }

  dispose = async () => {
    await this.backendService.close();
  };

  private getActionPayloadByNode = (node: Node, prevId: string | null) => {
    return {
      block: this.getBlockByNode(node),
      parent_id: node.parent || '',
      prev_id: prevId || '',
    }
  }

  private getBlockByNode = (node: Node) => {
    return {
      id: node.id,
      parent_id: node.parent || '',
      children_id: node.children,
      data: JSON.stringify(node.data),
      ty: node.type,
    }
  }

  private updated = (payload: Uint8Array) => {
    const dispatch = this.dispatch;
    if (!dispatch) return;
    const { events, is_remote } = DocEventPB.deserializeBinary(payload);
    if (!is_remote) return;
    events.forEach((event) => {
      event.event.forEach((_payload) => {
        const { path, id, value, command } = _payload;
        let valueJson;
        try {
          valueJson = JSON.parse(value);
        } catch {
          console.error('json parse error', value);
          return;
        }
        if (!valueJson) return;

        if (command === DeltaTypePB.Inserted || command === DeltaTypePB.Updated) {
          // set map key and value ( block map or children map)
          if (path[0] === 'blocks') {
            if ('data' in valueJson && typeof valueJson.data === 'string') {
              try {
                valueJson.data = JSON.parse(valueJson.data);
              } catch {
                console.error('valueJson data parse error', valueJson.data);
                return;
              }
            }
            const block = {
              id: valueJson.id,
              type: valueJson.ty as BlockType,
              parent: valueJson.parent,
              children: valueJson.children,
              data: valueJson.data,
            };

            dispatch(documentActions.setBlockMap(block));
          } else {
            dispatch(
              documentActions.setChildrenMap({
                id,
                childIds: valueJson,
              })
            );
          }
        } else {
          // remove map key ( block map or children map)
          if (path[0] === 'blocks') {
            dispatch(documentActions.removeBlockMapKey(id));
          } else {
            dispatch(documentActions.removeChildrenMapKey(id));
          }
        }
      });
    });
  };
}
