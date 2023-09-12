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
import { DOCUMENT_NAME, RANGE_NAME } from '$app/constants/document/name';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';

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
  const deltaOperator = new BlockDeltaOperator(document);
  const delta = deltaOperator.getDeltaWithBlockId(caret.id);

  if (!delta) return;
  const inTopEdge = caretInTopEdgeByDelta(delta, caret.index);

  if (!inTopEdge) {
    const index = transformIndexToPrevLine(delta, caret.index);

    return {
      id: caret.id,
      index,
      length: 0,
    };
  }

  const prevLineId = deltaOperator.findPrevTextLine(caret.id);

  if (!prevLineId) return;
  const relativeIndex = getIndexRelativeEnter(delta, caret.index);
  const prevLineDelta = deltaOperator.getDeltaWithBlockId(prevLineId);

  if (!prevLineDelta) return;
  const prevLineIndex = getLastLineIndex(prevLineDelta);
  const prevLineText = deltaOperator.getDeltaText(prevLineDelta);
  const newPrevLineIndex = prevLineIndex + relativeIndex;
  const prevLineLength = prevLineText.length;
  const index = newPrevLineIndex > prevLineLength ? prevLineLength : newPrevLineIndex;

  return {
    id: prevLineId,
    index,
    length: 0,
  };
}

export function transformToNextLineCaret(document: DocumentState, caret: RangeStatic) {
  const deltaOperator = new BlockDeltaOperator(document);
  const delta = deltaOperator.getDeltaWithBlockId(caret.id);

  if (!delta) return;
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

  const nextLineId = deltaOperator.findNextTextLine(caret.id);

  if (!nextLineId) return;
  const nextLineDelta = deltaOperator.getDeltaWithBlockId(nextLineId);

  if (!nextLineDelta) return;
  const nextLineText = deltaOperator.getDeltaText(nextLineDelta);
  const relativeIndex = getIndexRelativeEnter(delta, caret.index);
  const index = relativeIndex >= nextLineText.length ? nextLineText.length : relativeIndex;

  return {
    id: nextLineId,
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
