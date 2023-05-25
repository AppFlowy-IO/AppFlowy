import {
  BlockData,
  BlockType,
  DocumentState,
  NestedBlock,
  RangeSelectionState,
  TextDelta,
  TextSelection,
} from '$app/interfaces/document';
import { Descendant, Element, Text } from 'slate';
import { BlockPB } from '@/services/backend';
import { Log } from '$app/utils/log';
import { nanoid } from 'nanoid';
import { clone } from '$app/utils/tool';

export function slateValueToDelta(slateNodes: Descendant[]) {
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

export function getPrevNodeId(state: DocumentState, id: string) {
  const node = state.nodes[id];
  if (!node.parent) return;
  const parent = state.nodes[node.parent];
  const children = state.children[parent.children];
  const index = children.indexOf(id);
  const prevNodeId = children[index - 1];
  return prevNodeId;
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

export function getCollapsedRange(id: string, selection: TextSelection): RangeSelectionState {
  const point = {
    id,
    selection,
  };
  return {
    anchor: clone(point),
    focus: clone(point),
    isDragging: false,
    selection: [],
  };
}

export function iterateNodes(
  range: {
    startId: string;
    endId: string;
  },
  isForward: boolean,
  document: DocumentState,
  callback: (nodeId?: string) => boolean
) {
  const { startId, endId } = range;
  let currentId = startId;
  while (currentId && currentId !== endId) {
    if (isForward) {
      currentId = getNextLineId(document, currentId) || '';
    } else {
      currentId = getPrevLineId(document, currentId) || '';
    }
    if (callback(currentId)) {
      break;
    }
  }
}
export function getNodesInRange(
  range: {
    startId: string;
    endId: string;
  },
  isForward: boolean,
  document: DocumentState
) {
  const nodeIds: string[] = [];
  nodeIds.push(range.startId);
  iterateNodes(range, isForward, document, (nodeId) => {
    if (nodeId) {
      nodeIds.push(nodeId);
      return false;
    } else {
      return true;
    }
  });
  nodeIds.push(range.endId);
  return nodeIds;
}

export function nodeInRange(
  id: string,
  range: {
    startId: string;
    endId: string;
  },
  isForward: boolean,
  document: DocumentState
) {
  let match = false;
  iterateNodes(range, isForward, document, (nodeId) => {
    if (nodeId === id) {
      match = true;
      return true;
    }
    return false;
  });
  return match;
}
