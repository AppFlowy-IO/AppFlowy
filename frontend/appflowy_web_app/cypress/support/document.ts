import { BlockId, BlockType, YBlocks, YChildrenMap, YjsEditorKey, YTextMap } from '@/application/types';
import { nanoid } from 'nanoid';
import { Op } from 'quill-delta';
import * as Y from 'yjs';

export interface FromBlockJSON {
  type: string;
  children: FromBlockJSON[];
  data: Record<string, number | string | boolean>;
  text: Op[];
}

export class DocumentTest {
  public doc: Y.Doc;

  private blocks: YBlocks;

  private childrenMap: YChildrenMap;

  private textMap: YTextMap;

  private pageId: string;

  constructor () {
    const doc = new Y.Doc();

    this.doc = doc;
    const collab = doc.getMap(YjsEditorKey.data_section);
    const document = new Y.Map();
    const blocks = new Y.Map() as YBlocks;
    const pageId = nanoid(8);
    const meta = new Y.Map();
    const childrenMap = new Y.Map() as YChildrenMap;
    const textMap = new Y.Map() as YTextMap;

    const block = new Y.Map();

    block.set(YjsEditorKey.block_id, pageId);
    block.set(YjsEditorKey.block_type, BlockType.Page);
    block.set(YjsEditorKey.block_children, pageId);
    block.set(YjsEditorKey.block_external_id, pageId);
    block.set(YjsEditorKey.block_external_type, YjsEditorKey.text);
    block.set(YjsEditorKey.block_data, '');
    blocks.set(pageId, block);

    document.set(YjsEditorKey.page_id, pageId);
    document.set(YjsEditorKey.blocks, blocks);
    document.set(YjsEditorKey.meta, meta);
    meta.set(YjsEditorKey.children_map, childrenMap);
    meta.set(YjsEditorKey.text_map, textMap);
    collab.set(YjsEditorKey.document, document);

    this.blocks = blocks;
    this.childrenMap = childrenMap;
    this.textMap = textMap;
    this.pageId = pageId;
  }

  insertParagraph (text: string) {
    const blockId = nanoid(8);
    const block = new Y.Map();

    block.set(YjsEditorKey.block_id, blockId);
    block.set(YjsEditorKey.block_type, BlockType.Paragraph);
    block.set(YjsEditorKey.block_children, blockId);
    block.set(YjsEditorKey.block_external_id, blockId);
    block.set(YjsEditorKey.block_external_type, YjsEditorKey.text);
    block.set(YjsEditorKey.block_parent, this.pageId);
    block.set(YjsEditorKey.block_data, '');
    this.blocks.set(blockId, block);
    const pageChildren = this.childrenMap.get(this.pageId) ?? new Y.Array<BlockId>();

    pageChildren.push([blockId]);
    this.childrenMap.set(this.pageId, pageChildren);

    const blockText = new Y.Text();

    blockText.insert(0, text);
    this.textMap.set(blockId, blockText);

    return blockText;
  }

  fromJSON (json: FromBlockJSON[]) {

    this.fromJSONChildren(json, this.pageId);

    return this.doc;
  }

  private fromJSONChildren (children: FromBlockJSON[], parentId: BlockId) {
    const parentChildren = this.childrenMap.get(parentId) ?? new Y.Array<BlockId>();

    for (const child of children) {
      const blockId = nanoid(8);
      const block = new Y.Map();

      block.set(YjsEditorKey.block_id, blockId);
      block.set(YjsEditorKey.block_type, child.type);
      block.set(YjsEditorKey.block_children, blockId);
      block.set(YjsEditorKey.block_external_id, blockId);
      block.set(YjsEditorKey.block_external_type, YjsEditorKey.text);
      block.set(YjsEditorKey.block_parent, parentId);
      block.set(YjsEditorKey.block_data, JSON.stringify(child.data));
      this.blocks.set(blockId, block);

      parentChildren.push([blockId]);
      if (!this.childrenMap.has(parentId)) {
        this.childrenMap.set(parentId, parentChildren);
      }

      const blockText = new Y.Text();

      blockText.applyDelta(child.text);

      this.textMap.set(blockId, blockText);
      
      const blockChildren = new Y.Array<BlockId>();

      this.childrenMap.set(blockId, blockChildren);

      this.fromJSONChildren(child.children, blockId);
    }
  }

  toJSON () {
    return this.toJSONChildren(this.pageId);
  }

  private toJSONChildren (parentId: BlockId): FromBlockJSON[] {
    const parentChildren = this.childrenMap.get(parentId) ?? [];
    const children = [];

    for (const childId of parentChildren) {
      const child = this.blocks.get(childId);

      children.push({
        type: child.get(YjsEditorKey.block_type),
        data: JSON.parse(child.get(YjsEditorKey.block_data)),
        text: this.textMap.get(childId).toDelta(),
        children: this.toJSONChildren(childId),
      });
    }

    return children;
  }
}
