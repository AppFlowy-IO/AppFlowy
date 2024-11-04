import { YjsEditor } from '@/application/slate-yjs';
import { BlockJson } from '@/application/slate-yjs/types';
import { blockToSlateNode, deltaInsertToSlateNode } from '@/application/slate-yjs/utils/convert';
import {
  dataStringTOJson,
  getBlock,
  getChildrenArray,
  getPageId,
  getText,
} from '@/application/slate-yjs/utils/yjsOperations';
import { YBlock, YjsEditorKey } from '@/application/types';
import isEqual from 'lodash-es/isEqual';
import { Editor, Element, NodeEntry } from 'slate';
import { YEvent, YMapEvent, YTextEvent } from 'yjs';
import { YText } from 'yjs/dist/src/types/YText';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type BlockMapEvent = YMapEvent<any>

export function translateYEvents (editor: YjsEditor, events: Array<YEvent>) {
  console.log('=== Translating Yjs events ===', events);

  events.forEach((event) => {
    console.log(event.path);
    if (isEqual(event.path, ['document', 'blocks'])) {
      applyBlocksYEvent(editor, event as BlockMapEvent);
    }

    if (isEqual((event.path), ['document', 'blocks', event.path[2]])) {
      const blockId = event.path[2] as string;

      applyUpdateBlockYEvent(editor, blockId, event as YMapEvent<unknown>);
    }

    if (isEqual(event.path, ['document', 'meta', 'text_map', event.path[3]])) {
      const textId = event.path[3] as string;

      applyTextYEvent(editor, textId, event as YTextEvent);
    }
  });

}

function applyUpdateBlockYEvent (editor: YjsEditor, blockId: string, event: YMapEvent<unknown>) {
  const { target } = event;
  const block = target as YBlock;
  const newData = dataStringTOJson(block.get(YjsEditorKey.block_data));
  const [entry] = editor.nodes({
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId === blockId,
    mode: 'all',
  });

  if (!entry) {
    console.error('Block node not found', blockId);
    return [];
  }

  const [node, path] = entry as NodeEntry<Element>;
  const oldData = node.data as Record<string, unknown>;

  editor.apply({
    type: 'set_node',
    path,
    newProperties: {
      data: newData,
    },
    properties: {
      data: oldData,
    },
  });
}

function applyTextYEvent (editor: YjsEditor, textId: string, event: YTextEvent) {
  const { target } = event;

  const yText = target as YText;
  const delta = yText.toDelta();
  const slateDelta = delta.flatMap(deltaInsertToSlateNode);
  const [entry] = editor.nodes({
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId === textId,
    mode: 'all',
  });

  if (!entry) {
    console.error('Text node not found', textId);
    return [];
  }

  editor.apply({
    type: 'remove_node',
    path: entry[1],
    node: entry[0],
  });
  editor.apply({
    type: 'insert_node',
    path: entry[1],
    node: {
      textId,
      type: YjsEditorKey.text,
      children: slateDelta,
    },
  });

}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function applyBlocksYEvent (editor: YjsEditor, event: BlockMapEvent) {
  const { changes, keysChanged } = event;
  const { keys } = changes;

  const keyPath: Record<string, number[]> = {};

  keysChanged.forEach((key: string) => {
    const value = keys.get(key);

    if (!value) return;

    if (value.action === 'add') {
      handleNewBlock(editor, key, keyPath);

    } else if (value.action === 'delete') {
      handleDeleteNode(editor, key);
    } else if (value.action === 'update') {
      console.log('=== Applying block update Yjs event ===', key);
    }
  });

}

function handleNewBlock (editor: YjsEditor, key: string, keyPath: Record<string, number[]>) {
  const block = getBlock(key, editor.sharedRoot);
  const parentId = block.get(YjsEditorKey.block_parent);
  const pageId = getPageId(editor.sharedRoot);
  const parent = getBlock(parentId, editor.sharedRoot);
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), editor.sharedRoot);
  const index = parentChildren.toArray().findIndex((child) => child === key);
  const slateNode = blockToSlateNode(block.toJSON() as BlockJson);
  const textId = block.get(YjsEditorKey.block_external_id);
  const yText = getText(textId, editor.sharedRoot);
  const delta = yText.toDelta();
  const slateDelta = delta.flatMap(deltaInsertToSlateNode);

  if (slateDelta.length === 0) {
    slateDelta.push({
      text: '',
    });
  }

  const textNode: Element = {
    textId,
    type: YjsEditorKey.text,
    children: slateDelta,
  };
  let path = [index];

  if (parentId !== pageId) {
    const [parentEntry] = editor.nodes({
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId === parentId,
      mode: 'all',
      at: [],
    });

    if (!parentEntry) {
      if (keyPath[parentId]) {
        path = [...keyPath[parentId], index + 1];
      } else {
        console.error('Parent block not found', parentId);
        return [];
      }
    } else {
      const childrenLength = (parentEntry[0] as Element).children.length;

      path = [...parentEntry[1], Math.min(index + 1, childrenLength)];
    }
  }

  editor.apply({
    type: 'insert_node',
    path,
    node: {
      ...slateNode,
      children: [textNode],
    },
  });

  keyPath[key] = path;

}

function handleDeleteNode (editor: YjsEditor, key: string) {
  const [entry] = editor.nodes({
    at: [],
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId === key,
  });

  if (!entry) {
    console.error('Block not found');
    return [];
  }

  const [node, path] = entry;

  editor.apply({
    type: 'remove_node',
    path,
    node,
  });

}