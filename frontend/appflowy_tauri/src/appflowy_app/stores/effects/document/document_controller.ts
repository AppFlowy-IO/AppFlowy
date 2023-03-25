import * as Y from 'yjs';
import { IndexeddbPersistence } from 'y-indexeddb';
import { v4 } from 'uuid';
import { DocumentData } from '@/appflowy_app/interfaces/document';
import { createContext } from 'react';

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
    ydoc.on('updateV2', (update) => {
      console.log('======', update);
    })
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
        Object.assign(obj.yarrays, {
          [value.children]: ydoc.getArray(value.children).toArray()
        });
      }
      if (value.data.text) {
        Object.assign(obj.ytexts, {
          [value.data.text]: ydoc.getText(value.data.text).toDelta()
        })
      }
    });
    return obj;
  }


  yTextApply = (yTextId: string, delta: Delta) => {
    console.log("====", yTextId, delta);
    const ydoc = this._ydoc;
    const ytext = ydoc.getText(yTextId);
    ytext.applyDelta(delta);
  }

}
