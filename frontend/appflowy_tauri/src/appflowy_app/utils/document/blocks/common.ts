import { BlockData, BlockType, DocumentState, NestedBlock, TextDelta } from '$app/interfaces/document';
import { Descendant, Editor, Element, Text } from 'slate';
import { BlockPB } from '@/services/backend';
import { Log } from '$app/utils/log';
import { nanoid } from 'nanoid';
import { getAfterRangeAt } from '$app/utils/document/slate/text';

export function deltaToSlateValue(delta: TextDelta[]) {
  const slateNode = {
    type: 'paragraph',
    children: [{ text: '' }],
  };
  const slateNodes = [slateNode];
  if (delta.length > 0) {
    slateNode.children = delta.map((d) => {
      return {
        ...d.attributes,
        text: d.insert,
      };
    });
  }
  return slateNodes;
}

export function getDeltaAfterSelection(editor: Editor): TextDelta[] | undefined {
  const selection = editor.selection;
  if (!selection) return;
  const slateNodes = Editor.fragment(editor, getAfterRangeAt(editor, selection));
  const delta = getDeltaFromSlateNodes(slateNodes);
  return delta;
}

export function getDeltaFromSlateNodes(slateNodes: Descendant[]) {
  const element = slateNodes[0] as Element;
  const children = element.children as Text[];
  return children.map((child) => {
    const { text, ...attributes } = child;
    return {
      insert: text,
      attributes,
    };
  });
}

export function blockPB2Node(block: BlockPB) {
  let data = {};
  try {
    data = JSON.parse(block.data);
  } catch {
    Log.error('[Document Open] json parse error', block.data);
  }
  const node = {
    id: block.id,
    type: block.ty as BlockType,
    parent: block.parent_id,
    children: block.children_id,
    data,
  };
  return node;
}

export function generateId() {
  return nanoid(10);
}

export function getPrevLineId(state: DocumentState, id: string) {
  const node = state.nodes[id];
  if (!node.parent) return;
  const parent = state.nodes[node.parent];
  const children = state.children[parent.children];
  const index = children.indexOf(id);
  const prevNodeId = children[index - 1];
  const prevNode = state.nodes[prevNodeId];
  if (!prevNode) {
    return parent.id;
  }
  // find prev line
  let prevLineId = prevNode.id;
  while (prevLineId) {
    const prevLineChildren = state.children[state.nodes[prevLineId].children];
    if (prevLineChildren.length === 0) break;
    prevLineId = prevLineChildren[prevLineChildren.length - 1];
  }
  return prevLineId || parent.id;
}

export function getNextLineId(state: DocumentState, id: string) {
  const node = state.nodes[id];
  if (!node.parent) return;

  const firstChild = state.children[node.children][0];
  if (firstChild) return firstChild;

  let nextNodeId = getNextNodeId(state, id);
  let parent: NestedBlock | null = state.nodes[node.parent];
  while (!nextNodeId && parent) {
    nextNodeId = getNextNodeId(state, parent.id);
    parent = parent.parent ? state.nodes[parent.parent] : null;
  }
  return nextNodeId;
}

export function getNextNodeId(state: DocumentState, id: string) {
  const node = state.nodes[id];
  if (!node.parent) return;
  const parent = state.nodes[node.parent];
  const children = state.children[parent.children];
  const index = children.indexOf(id);
  const nextNodeId = children[index + 1];
  return nextNodeId;
}

export function newBlock<Type>(type: BlockType, parentId: string, data: BlockData<Type>): NestedBlock<Type> {
  return {
    id: generateId(),
    type,
    parent: parentId,
    children: generateId(),
    data,
  };
}
