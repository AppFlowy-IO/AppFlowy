import * as Y from 'yjs';
import { IndexeddbPersistence } from 'y-indexeddb';
import { v4 } from 'uuid';
import { DocumentData, NestedBlock } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';
import { BlockType } from '@/appflowy_app/interfaces';

export type DeltaAttributes = {
  retain: number;
  attributes: Record<string, unknown>;
};

export type DeltaRetain = { retain: number };
export type DeltaDelete = { delete: number };
export type DeltaInsert = {
  insert: string | Y.XmlText;
  attributes?: Record<string, unknown>;
};

export type InsertDelta = Array<DeltaInsert>;
export type Delta = Array<
  DeltaRetain | DeltaDelete | DeltaInsert | DeltaAttributes
>;


export const YDocControllerContext = createContext<YDocController | null>(null);

export class YDocController {
  private _ydoc: Y.Doc;
  private readonly provider: IndexeddbPersistence;

  constructor(private id: string) {
    this._ydoc = new Y.Doc();
    this.provider = new IndexeddbPersistence(`document-${this.id}`, this._ydoc);
    this._ydoc.on('update', this.handleUpdate);
  }

  handleUpdate = (update: Uint8Array, origin: any) => {
    const isLocal = origin === null;
    Y.logUpdate(update);
  }


  createDocument = async () => {
    await this.provider.whenSynced;
    const ydoc = this._ydoc;
    const blocks = ydoc.getMap('blocks');
    const rootNode = ydoc.getArray("root");

    // create page block for root node
    const rootId = v4();
    rootNode.push([rootId])
    const rootChildrenId = v4();
    const rootChildren = ydoc.getArray(rootChildrenId);
    const rootTitleId = v4();
    const yTitle = ydoc.getText(rootTitleId);
    yTitle.insert(0, "");
    const root = {
      id: rootId,
      type: 'page',
      data: {
        text: rootTitleId
      },
      parent: null,
      children: rootChildrenId
    };
    blocks.set(root.id, root);

    // create text block for first line
    const textId = v4();
    const yTextId = v4();
    const ytext = ydoc.getText(yTextId);
    ytext.insert(0, "");
    const textChildrenId = v4();
    ydoc.getArray(textChildrenId);
    const text = {
      id: textId,
      type: 'text',
      data: {
        text: yTextId,
      },
      parent: rootId,
      children: textChildrenId,
    }
    
    // add text block to root children
    rootChildren.push([textId]);
    blocks.set(text.id, text);
  }

  open = async (): Promise<DocumentData> => {
    await this.provider.whenSynced;
    const ydoc = this._ydoc;
    
    const blocks = ydoc.getMap('blocks');
    const obj: DocumentData = {
      rootId: ydoc.getArray<string>('root').toArray()[0] || '',
      blocks: blocks.toJSON(),
      ytexts: {},
      yarrays: {}
    };
    
    Object.keys(obj.blocks).forEach(key => {
      const value = obj.blocks[key];
      if (value.children) {
        const yarray = ydoc.getArray<string>(value.children);
        Object.assign(obj.yarrays, {
          [value.children]: yarray.toArray()
        });
      }
      if (value.data.text) {
        const ytext = ydoc.getText(value.data.text);
        Object.assign(obj.ytexts, {
          [value.data.text]: ytext.toDelta()
        })
      }
    });

    blocks.observe(this.handleBlocksEvent);
    return obj;
  }

  insert(node: {
    id: string,
    type: BlockType,
    delta?: Delta
  }, parentId: string, prevId: string) {
    const blocks = this._ydoc.getMap<NestedBlock>('blocks');
    const parent = blocks.get(parentId);
    if (!parent) return;
    const insertNode =  {
      id: node.id,
      type: node.type,
      data: {
        text: ''
      },
      children: '',
      parent: ''
    }
    // create ytext
    if (node.delta) {
      const ytextId = v4();
      const ytext = this._ydoc.getText(ytextId);
      ytext.applyDelta(node.delta);
      insertNode.data.text = ytextId;
    }
    // create children
    const yArrayId = v4();
    this._ydoc.getArray(yArrayId);
    insertNode.children = yArrayId;
    // insert in parent's children
    const children = this._ydoc.getArray(parent.children);
    const index = children.toArray().indexOf(prevId) + 1;
    children.insert(index, [node.id]);
    insertNode.parent = parentId;
    // set in blocks
    this._ydoc.getMap('blocks').set(node.id, insertNode);
  }

  transact(actions: (() => void)[]) {
    const ydoc = this._ydoc;
    console.log('====transact')
    ydoc.transact(() => {
      actions.forEach(action => {
        action();
      });
    });
  }

  yTextApply = (yTextId: string, delta: Delta) => {
    const ydoc = this._ydoc;
    const ytext = ydoc.getText(yTextId);
    ytext.applyDelta(delta);
    console.log("====", yTextId, delta);
  }

  close = () => {
    const blocks = this._ydoc.getMap('blocks');
    blocks.unobserve(this.handleBlocksEvent);
  }

  private handleBlocksEvent = (mapEvent: Y.YMapEvent<unknown>) => {
    console.log(mapEvent.changes);
  }

  private handleTextEvent = (textEvent: Y.YTextEvent) => {
    console.log(textEvent.changes);
  }

  private handleArrayEvent = (arrayEvent: Y.YArrayEvent<string>) => {
    console.log(arrayEvent.changes);
  }

}
