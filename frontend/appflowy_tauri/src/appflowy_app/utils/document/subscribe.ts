import { DeltaTypePB } from '@/services/backend/models/flowy-document2';
import { BlockPBValue, BlockType, ChangeType, DocumentState, NestedBlock } from '$app/interfaces/document';
import { Log } from '../log';
import { isEqual } from '$app/utils/tool';
import { BLOCK_MAP_NAME, CHILDREN_MAP_NAME, META_NAME, TEXT_MAP_NAME } from '$app/constants/document/name';
import Delta, { Op } from 'quill-delta';

// This is a list of all the possible changes that can happen to document data
const matchCases = [
  { match: matchBlockInsert, type: ChangeType.BlockInsert, onMatch: onMatchBlockInsert },
  { match: matchBlockUpdate, type: ChangeType.BlockUpdate, onMatch: onMatchBlockUpdate },
  { match: matchBlockDelete, type: ChangeType.BlockDelete, onMatch: onMatchBlockDelete },
  { match: matchChildrenMapInsert, type: ChangeType.ChildrenMapInsert, onMatch: onMatchChildrenInsert },
  { match: matchChildrenMapUpdate, type: ChangeType.ChildrenMapUpdate, onMatch: onMatchChildrenUpdate },
  { match: matchChildrenMapDelete, type: ChangeType.ChildrenMapDelete, onMatch: onMatchChildrenDelete },
  { match: matchDeltaMapInsert, type: ChangeType.DeltaMapInsert, onMatch: onMatchDeltaInsert },
  { match: matchDeltaMapUpdate, type: ChangeType.DeltaMapUpdate, onMatch: onMatchDeltaUpdate },
  { match: matchDeltaMapDelete, type: ChangeType.DeltaMapDelete, onMatch: onMatchDeltaDelete },
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
    value: BlockPBValue & string[] & Op[];
  }
) {
  const matchCase = matchCases.find((item) => item.match(command, path));

  if (matchCase) {
    matchCase.onMatch(state, id, value);
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

/**
 * @param command DeltaTypePB.Inserted
 * @param command
 * @param path [META_NAME, TEXT_MAP_NAME]
 */
function matchDeltaMapInsert(command: DeltaTypePB, path: string[]) {
  if (path.length !== 2) return false;
  return command === DeltaTypePB.Inserted && path[0] === META_NAME && path[1] === TEXT_MAP_NAME;
}

/**
 * @param command DeltaTypePB.Updated
 * @param command
 * @param path [META_NAME, TEXT_MAP_NAME, id]
 */
function matchDeltaMapUpdate(command: DeltaTypePB, path: string[]) {
  if (path.length !== 3) return false;
  return (
    command === DeltaTypePB.Updated && path[0] === META_NAME && path[1] === TEXT_MAP_NAME && typeof path[2] === 'string'
  );
}

/**
 * @param command DeltaTypePB.Removed
 * @param path [META_NAME, TEXT_MAP_NAME, id]
 */
function matchDeltaMapDelete(command: DeltaTypePB, path: string[]) {
  if (path.length !== 3) return false;
  return (
    command === DeltaTypePB.Removed && path[0] === META_NAME && path[1] === TEXT_MAP_NAME && typeof path[2] === 'string'
  );
}

function onMatchBlockInsert(state: DocumentState, blockId: string, blockValue: BlockPBValue) {
  state.nodes[blockId] = blockChangeValue2Node(blockValue);
}

function onMatchBlockUpdate(state: DocumentState, blockId: string, blockValue: BlockPBValue) {
  const block = blockChangeValue2Node(blockValue);
  const node = state.nodes[blockId];

  if (!node) return;

  if (isEqual(node, block)) return;
  state.nodes[blockId] = block;
  return;
}

function onMatchBlockDelete(state: DocumentState, blockId: string, _blockValue: BlockPBValue) {
  delete state.nodes[blockId];
}

function onMatchChildrenInsert(state: DocumentState, id: string, children: string[]) {
  state.children[id] = children;
}

function onMatchChildrenUpdate(state: DocumentState, id: string, newChildren: string[]) {
  const children = state.children[id];

  if (!children) return;
  state.children[id] = newChildren;
}

function onMatchChildrenDelete(state: DocumentState, id: string, _children: string[]) {
  delete state.children[id];
}

function onMatchDeltaInsert(state: DocumentState, id: string, ops: Op[]) {
  state.deltaMap[id] = JSON.stringify(ops);
}

function onMatchDeltaUpdate(state: DocumentState, id: string, ops: Op[]) {
  const delta = new Delta(ops);
  const oldDelta = new Delta(JSON.parse(state.deltaMap[id]));
  const newDelta = oldDelta.compose(delta);

  state.deltaMap[id] = JSON.stringify(newDelta.ops);
}

function onMatchDeltaDelete(state: DocumentState, id: string, _ops: Op[]) {
  delete state.deltaMap[id];
}

/**
 * convert block change value to node
 * @param value
 */
export function blockChangeValue2Node(value: BlockPBValue): NestedBlock {
  const block: NestedBlock = {
    id: value.id,
    type: value.ty as BlockType,
    parent: value.parent,
    children: value.children,
    data: {},
    externalId: value.external_id,
    externalType: value.external_type,
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
    return value;
  }

  return valueJson;
}
