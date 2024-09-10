import { BlockId, BlockType, YBlocks, YChildrenMap, YjsEditorKey, YTextMap } from '@/application/types';
import { nanoid } from 'nanoid';
import * as Y from 'yjs';

export class DocumentTest {
  public doc: Y.Doc;

  private blocks: YBlocks;

  private childrenMap: YChildrenMap;

  private textMap: YTextMap;

  private pageId: string;

  constructor() {
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

  insertParagraph(text: string) {
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
}
