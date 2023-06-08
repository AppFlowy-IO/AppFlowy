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
  getAfterExtentDeltaByRange,
  getBeofreExtentDeltaByRange,
  getDeltaText,
  getIndexRelativeEnter,
  getLastLineIndex,
  transformIndexToNextLine,
  transformIndexToPrevLine,
} from '$app/utils/document/delta';

export function getMiddleIds(document: DocumentState, startId: string, endId: string) {
  const middleIds = [];
  let currentId: string | undefined = startId;
  while (currentId && currentId !== endId) {
    const nextId = getNextLineId(document, currentId);
    if (nextId && nextId !== endId) {
      middleIds.push(nextId);
    }
    currentId = nextId;
  }
  return middleIds;
}

export function getStartAndEndIdsByRange(rangeState: RangeState) {
  const { anchor, focus } = rangeState;
  if (!anchor || !focus) return [];
  if (anchor.id === focus.id) return [anchor.id];
  const isForward = anchor.point.y < focus.point.y;
  const startId = isForward ? anchor.id : focus.id;
  const endId = isForward ? focus.id : anchor.id;
  return [startId, endId];
}

export function getMiddleIdsByRange(rangeState: RangeState, document: DocumentState) {
  const ids = getStartAndEndIdsByRange(rangeState);
  if (ids.length < 2) return;
  const [startId, endId] = ids;
  return getMiddleIds(document, startId, endId);
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

export function getStartAndEndExtentDelta(state: RootState) {
  const rangeState = state.documentRange;
  const ids = getStartAndEndIdsByRange(rangeState);
  if (ids.length === 0) return;
  const startId = ids[0];
  const endId = ids[ids.length - 1];
  const { ranges } = rangeState;
  // get start and end delta
  const startRange = ranges[startId];
  const endRange = ranges[endId];
  if (!startRange || !endRange) return;
  const startNode = state.document.nodes[startId];
  const startNodeDelta = new Delta(startNode.data.delta);
  const startBeforeExtentDelta = getBeofreExtentDeltaByRange(startNodeDelta, startRange);

  const endNode = state.document.nodes[endId];
  const endNodeDelta = new Delta(endNode.data.delta);
  const endAfterExtentDelta = getAfterExtentDeltaByRange(endNodeDelta, endRange);

  return {
    startNode,
    endNode,
    startDelta: startBeforeExtentDelta,
    endDelta: endAfterExtentDelta,
  };
}

export function getMergeEndDeltaToStartActionsByRange(
  state: RootState,
  controller: DocumentController,
  insertDelta?: Delta
) {
  const actions = [];
  const { startDelta, endDelta, endNode, startNode } = getStartAndEndExtentDelta(state) || {};
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
    const children = state.document.children[endNode.children].map((id) => state.document.nodes[id]);

    const moveChildrenActions = getMoveChildrenActions({
      target: startNode,
      children,
      controller,
    });
    actions.push(...moveChildrenActions);
    // delete end node
    actions.push(controller.getDeleteAction(endNode));
  }

  return actions;
}

export function getMoveChildrenActions({
  target,
  children,
  controller,
  prevId = '',
}: {
  target: NestedBlock;
  children: NestedBlock[];
  controller: DocumentController;
  prevId?: string;
}) {
  // move children
  const config = blockConfig[target.type];
  const targetParentId = config.canAddChild ? target.id : target.parent;
  if (!targetParentId) return [];
  const targetPrevId = targetParentId === target.id ? prevId : target.id;
  const moveActions = controller.getMoveChildrenAction(children, targetParentId, targetPrevId);
  return moveActions;
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
