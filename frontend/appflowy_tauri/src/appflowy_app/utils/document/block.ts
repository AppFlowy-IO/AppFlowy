import { BlockData, BlockType, DocumentState, NestedBlock } from '$app/interfaces/document';
import { BlockPB } from '@/services/backend';
import { Log } from '$app/utils/log';
import { nanoid } from 'nanoid';

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
