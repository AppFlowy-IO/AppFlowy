import {
  BlockType,
  ControllerAction,
  DocumentState,
  NestedBlock,
  RangeState,
  RangeStatic,
  SplitRelationship,
} from '$app/interfaces/document';
import { getNextLineId, getPrevLineId, newBlock } from '$app/utils/document/block';
import Delta from 'quill-delta';
import { RootState } from '$app/stores/store';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { blockConfig } from '$app/constants/document/config';
import {
  caretInBottomEdgeByDelta,
  caretInTopEdgeByDelta,
  getDeltaText,
  getIndexRelativeEnter,
  getLastLineIndex,
  transformIndexToNextLine,
  transformIndexToPrevLine,
} from '$app/utils/document/delta';

export function getMiddleIdsByRange(rangeState: RangeState, document: DocumentState) {
  const { anchor, focus } = rangeState;
  if (!anchor || !focus) return;
  if (anchor.id === focus.id) return;
  const isForward = anchor.point.y < focus.point.y;
  // get all ids between anchor and focus
  const amendIds = [];
  const startId = isForward ? anchor.id : focus.id;
  const endId = isForward ? focus.id : anchor.id;

  let currentId: string | undefined = startId;
  while (currentId && currentId !== endId) {
    const nextId = getNextLineId(document, currentId);
    if (nextId && nextId !== endId) {
      amendIds.push(nextId);
    }
    currentId = nextId;
  }
  return amendIds;
}

export function getAfterMergeCaretByRange(rangeState: RangeState, insertDelta?: Delta) {
  const { anchor, focus, ranges } = rangeState;
  if (!anchor || !focus) return;
  if (anchor.id === focus.id) return;

  const isForward = anchor.point.y < focus.point.y;
  const startId = isForward ? anchor.id : focus.id;
  const startRange = ranges[startId];
  if (!startRange) return;
  const offset = insertDelta ? insertDelta.length() : 0;

  return {
    id: startId,
    index: startRange.index + offset,
    length: 0,
  };
}

export function getStartAndEndDeltaExpectRange(state: RootState) {
  const rangeState = state.documentRange;
  const { anchor, focus, ranges } = rangeState;
  if (!anchor || !focus) return;
  if (anchor.id === focus.id) return;

  const isForward = anchor.point.y < focus.point.y;
  const startId = isForward ? anchor.id : focus.id;
  const endId = isForward ? focus.id : anchor.id;

  // get start and end delta
  const startRange = ranges[startId];
  const endRange = ranges[endId];
  if (!startRange || !endRange) return;
  const startNode = state.document.nodes[startId];
  let startDelta = new Delta(startNode.data.delta);
  startDelta = startDelta.slice(0, startRange.index);

  const endNode = state.document.nodes[endId];
  let endDelta = new Delta(endNode.data.delta);
  endDelta = endDelta.slice(endRange.index + endRange.length);

  return {
    startNode,
    endNode,
    startDelta,
    endDelta,
  };
}
export function getMergeEndDeltaToStartActionsByRange(
  state: RootState,
  controller: DocumentController,
  insertDelta?: Delta
) {
  const actions = [];
  const { startDelta, endDelta, endNode, startNode } = getStartAndEndDeltaExpectRange(state) || {};
  if (!startDelta || !endDelta || !endNode || !startNode) return;
  // merge start and end nodes
  const mergeDelta = startDelta.concat(insertDelta || new Delta()).concat(endDelta);
  actions.push(
    controller.getUpdateAction({
      ...startNode,
      data: {
        delta: mergeDelta.ops,
      },
    })
  );
  if (endNode.id !== startNode.id) {
    // delete end node
    actions.push(controller.getDeleteAction(endNode));
  }

  return actions;
}

export function getInsertEnterNodeFields(sourceNode: NestedBlock) {
  if (!sourceNode.parent) return;
  const parentId = sourceNode.parent;

  const config = blockConfig[sourceNode.type].splitProps || {
    nextLineRelationShip: SplitRelationship.NextSibling,
    nextLineBlockType: BlockType.TextBlock,
  };

  const newNodeType = config.nextLineBlockType;
  const relationShip = config.nextLineRelationShip;
  const defaultData = blockConfig[newNodeType].defaultData;
  // if the defaultData property is not defined for the new block type, we throw an error.
  if (!defaultData) {
    throw new Error(`Cannot split node of type ${sourceNode.type} to ${newNodeType}`);
  }
  const newParentId = relationShip === SplitRelationship.NextSibling ? parentId : sourceNode.id;
  const newPrevId = relationShip === SplitRelationship.NextSibling ? sourceNode.id : '';

  return {
    parentId: newParentId,
    prevId: newPrevId,
    type: newNodeType,
    data: defaultData,
  };
}

export function getInsertEnterNodeAction(
  sourceNode: NestedBlock,
  insertNodeDelta: Delta,
  controller: DocumentController
) {
  const insertNodeFields = getInsertEnterNodeFields(sourceNode);
  if (!insertNodeFields) return;
  const { type, data, parentId, prevId } = insertNodeFields;
  const insertNode = newBlock<any>(type, parentId, {
    ...data,
    delta: insertNodeDelta.ops,
  });

  return {
    id: insertNode.id,
    action: controller.getInsertAction(insertNode, prevId),
  };
}

export function findPrevHasDeltaNode(state: DocumentState, id: string) {
  const prevLineId = getPrevLineId(state, id);
  if (!prevLineId) return;
  let prevLine = state.nodes[prevLineId];
  // Find the prev line that has delta
  while (prevLine && !prevLine.data.delta) {
    const id = getPrevLineId(state, prevLine.id);
    if (!id) return;
    prevLine = state.nodes[id];
  }
  return prevLine;
}

export function findNextHasDeltaNode(state: DocumentState, id: string) {
  const nextLineId = getNextLineId(state, id);
  if (!nextLineId) return;
  let nextLine = state.nodes[nextLineId];
  // Find the next line that has delta
  while (nextLine && !nextLine.data.delta) {
    const id = getNextLineId(state, nextLine.id);
    if (!id) return;
    nextLine = state.nodes[id];
  }
  return nextLine;
}

export function isPrintableKeyEvent(event: KeyboardEvent) {
  const key = event.key;
  const isPrintable = key.length === 1;

  return isPrintable;
}

export function getLeftCaretByRange(rangeState: RangeState) {
  const { anchor, ranges, focus } = rangeState;
  if (!anchor || !focus) return;
  const isForward = anchor.point.y < focus.point.y;
  const startId = isForward ? anchor.id : focus.id;

  const range = ranges[startId];
  if (!range) return;
  return {
    id: startId,
    index: range.index,
    length: 0,
  };
}

export function getRightCaretByRange(rangeState: RangeState) {
  const { anchor, focus, ranges, caret } = rangeState;
  if (!anchor || !focus) return;
  const isForward = anchor.point.y < focus.point.y;
  const endId = isForward ? focus.id : anchor.id;

  const range = ranges[endId];
  if (!range) return;

  return {
    id: endId,
    index: range.index + range.length,
    length: 0,
  };
}

export function transformToPrevLineCaret(document: DocumentState, caret: RangeStatic) {
  const delta = new Delta(document.nodes[caret.id].data.delta);
  const inTopEdge = caretInTopEdgeByDelta(delta, caret.index);

  if (!inTopEdge) {
    const index = transformIndexToPrevLine(delta, caret.index);
    return {
      id: caret.id,
      index,
      length: 0,
    };
  }
  const prevLine = findPrevHasDeltaNode(document, caret.id);
  if (!prevLine) return;
  const relativeIndex = getIndexRelativeEnter(delta, caret.index);
  const prevLineIndex = getLastLineIndex(new Delta(prevLine.data.delta));
  const prevLineText = getDeltaText(new Delta(prevLine.data.delta));
  const newPrevLineIndex = prevLineIndex + relativeIndex;
  const prevLineLength = prevLineText.length;
  const index = newPrevLineIndex > prevLineLength ? prevLineLength : newPrevLineIndex;
  return {
    id: prevLine.id,
    index,
    length: 0,
  };
}

export function transformToNextLineCaret(document: DocumentState, caret: RangeStatic) {
  const delta = new Delta(document.nodes[caret.id].data.delta);
  const inBottomEdge = caretInBottomEdgeByDelta(delta, caret.index);
  if (!inBottomEdge) {
    const index = transformIndexToNextLine(delta, caret.index);
    return {
      id: caret.id,
      index,
      length: 0,
    };
    return;
  }

  const nextLine = findNextHasDeltaNode(document, caret.id);
  if (!nextLine) return;
  const nextLineText = getDeltaText(new Delta(nextLine.data.delta));
  const relativeIndex = getIndexRelativeEnter(delta, caret.index);
  const index = relativeIndex >= nextLineText.length ? nextLineText.length : relativeIndex;

  return {
    id: nextLine.id,
    index,
    length: 0,
  };
}

export function getDuplicateActions(
  id: string,
  parentId: string,
  document: DocumentState,
  controller: DocumentController
) {
  const actions: ControllerAction[] = [];
  const node = document.nodes[id];
  if (!node) return;
  // duplicate new node
  const newNode = newBlock<any>(node.type, parentId, {
    ...node.data,
  });
  actions.push(controller.getInsertAction(newNode, node.id));
  const children = document.children[node.children];
  children.forEach((child) => {
    const duplicateChildActions = getDuplicateActions(child, newNode.id, document, controller);
    if (!duplicateChildActions) return;
    actions.push(...duplicateChildActions.actions);
  });

  return {
    actions,
    newNodeId: newNode.id,
  };
}
