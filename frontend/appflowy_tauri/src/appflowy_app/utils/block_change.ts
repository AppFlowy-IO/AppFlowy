import { DeltaTypePB } from '@/services/backend/models/flowy-document2';
import { BlockType, NestedBlock, DocumentState, ChangeType, BlockPBValue } from '../interfaces/document';
import { Log } from './log';
import { BLOCK_MAP_NAME, CHILDREN_MAP_NAME, META_NAME } from '../constants/block';

// This is a list of all the possible changes that can happen to document data
const matchCases = [
  { match: matchBlockInsert, type: ChangeType.BlockInsert, onMatch: onMatchBlockInsert },
  { match: matchBlockUpdate, type: ChangeType.BlockUpdate, onMatch: onMatchBlockUpdate },
  { match: matchBlockDelete, type: ChangeType.BlockDelete, onMatch: onMatchBlockDelete },
  { match: matchChildrenMapInsert, type: ChangeType.ChildrenMapInsert, onMatch: onMatchChildrenInsert },
  { match: matchChildrenMapUpdate, type: ChangeType.ChildrenMapUpdate, onMatch: onMatchChildrenUpdate },
  { match: matchChildrenMapDelete, type: ChangeType.ChildrenMapDelete, onMatch: onMatchChildrenDelete },
];

export function matchChange(
  state: DocumentState,
  {
    command,
    path,
    id,
    value,
  }: {
    command: DeltaTypePB;
    path: string[];
    id: string;
    value: BlockPBValue & string[];
  },
  isRemote?: boolean
) {
  const matchCase = matchCases.find((item) => item.match(command, path));

  if (matchCase) {
    matchCase.onMatch(state, id, value, isRemote);
  }
}

/**
 * @param command DeltaTypePB.Inserted
 * @param path [BLOCK_MAP_NAME]
 */
function matchBlockInsert(command: DeltaTypePB, path: string[]) {
  if (path.length !== 1) return false;
  return command === DeltaTypePB.Inserted && path[0] === BLOCK_MAP_NAME;
}

/**
 * @param command DeltaTypePB.Updated
 * @param path [BLOCK_MAP_NAME, blockId]
 */
function matchBlockUpdate(command: DeltaTypePB, path: string[]) {
  if (path.length !== 2) return false;
  return command === DeltaTypePB.Updated && path[0] === BLOCK_MAP_NAME && typeof path[1] === 'string';
}

/**
 * @param command DeltaTypePB.Removed
 * @param path [BLOCK_MAP_NAME, blockId]
 */
function matchBlockDelete(command: DeltaTypePB, path: string[]) {
  if (path.length !== 2) return false;
  return command === DeltaTypePB.Removed && path[0] === BLOCK_MAP_NAME && typeof path[1] === 'string';
}

/**
 * @param command DeltaTypePB.Inserted
 * @param path [META_NAME, CHILDREN_MAP_NAME]
 */
function matchChildrenMapInsert(command: DeltaTypePB, path: string[]) {
  if (path.length !== 2) return false;
  return command === DeltaTypePB.Inserted && path[0] === META_NAME && path[1] === CHILDREN_MAP_NAME;
}

/**
 * @param command DeltaTypePB.Updated
 * @param path [META_NAME, CHILDREN_MAP_NAME, id]
 */
function matchChildrenMapUpdate(command: DeltaTypePB, path: string[]) {
  if (path.length !== 3) return false;
  return (
    command === DeltaTypePB.Updated &&
    path[0] === META_NAME &&
    path[1] === CHILDREN_MAP_NAME &&
    typeof path[2] === 'string'
  );
}

/**
 * @param command DeltaTypePB.Removed
 * @param path [META_NAME, CHILDREN_MAP_NAME, id]
 */
function matchChildrenMapDelete(command: DeltaTypePB, path: string[]) {
  if (path.length !== 3) return false;
  return (
    command === DeltaTypePB.Removed &&
    path[0] === META_NAME &&
    path[1] === CHILDREN_MAP_NAME &&
    typeof path[2] === 'string'
  );
}

function onMatchBlockInsert(state: DocumentState, blockId: string, blockValue: BlockPBValue, _isRemote?: boolean) {
  const block = blockChangeValue2Node(blockValue);
  state.nodes[blockId] = block;
}

function onMatchBlockUpdate(state: DocumentState, blockId: string, blockValue: BlockPBValue, isRemote?: boolean) {
  const block = blockChangeValue2Node(blockValue);
  const node = state.nodes[blockId];
  if (!node) return;
  // if the change is from remote, we should update all fields
  if (isRemote) {
    state.nodes[blockId] = block;
    return;
  }
  // if the change is from local, we should update all fields except `data`,
  // because we will update `data` field in `updateNodeData` action
  const shouldUpdate = node.parent !== block.parent || node.type !== block.type || node.children !== block.children;
  if (shouldUpdate) {
    state.nodes[blockId] = {
      ...block,
      data: node.data,
    };
  }
  return;
}

function onMatchBlockDelete(state: DocumentState, blockId: string, blockValue: BlockPBValue, _isRemote?: boolean) {
  const index = state.selections.indexOf(blockId);
  if (index > -1) {
    state.selections.splice(index, 1);
  }
  delete state.textSelections[blockId];
  delete state.nodes[blockId];
}

function onMatchChildrenInsert(state: DocumentState, id: string, children: string[], _isRemote?: boolean) {
  state.children[id] = children;
}

function onMatchChildrenUpdate(state: DocumentState, id: string, newChildren: string[], _isRemote?: boolean) {
  const children = state.children[id];
  if (!children) return;
  state.children[id] = newChildren;
}

function onMatchChildrenDelete(state: DocumentState, id: string, _children: string[], _isRemote?: boolean) {
  delete state.children[id];
}

/**
 * convert block change value to node
 * @param value
 */
export function blockChangeValue2Node(value: BlockPBValue): NestedBlock {
  const block = {
    id: value.id,
    type: value.ty as BlockType,
    parent: value.parent,
    children: value.children,
    data: {},
  };
  if ('data' in value && typeof value.data === 'string') {
    try {
      Object.assign(block, {
        data: JSON.parse(value.data),
      });
    } catch {
      Log.error('[onDataChange] valueJson data parse error', block.data);
    }
  }

  return block;
}

export function parseValue(value: string) {
  let valueJson;
  try {
    valueJson = JSON.parse(value);
  } catch {
    Log.error('[onDataChange] json parse error', value);
    return;
  }
  return valueJson;
}
