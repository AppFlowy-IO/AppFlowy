import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { getMiddleIds, getMoveChildrenActions, getStartAndEndIdsByRange } from '$app/utils/document/action';
import { BlockCopyData, BlockType, DocumentBlockJSON } from '$app/interfaces/document';
import Delta from 'quill-delta';
import { getDeltaByRange } from '$app/utils/document/delta';
import { deleteRangeAndInsertThunk } from '$app_reducers/document/async-actions/range';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import {
  generateBlocks,
  getAppendBlockDeltaAction,
  getCopyBlock,
  getInsertBlockActions,
} from '$app/utils/document/copy_paste';
import { rangeActions } from '$app_reducers/document/slice';

export const copyThunk = createAsyncThunk<
  void,
  {
    setClipboardData: (data: BlockCopyData) => void;
  }
>('document/copy', async (payload, thunkAPI) => {
  const { getState } = thunkAPI;
  const { setClipboardData } = payload;
  const state = getState() as RootState;
  const { document, documentRange } = state;
  const startAndEndIds = getStartAndEndIdsByRange(documentRange);
  if (startAndEndIds.length === 0) return;
  const result: DocumentBlockJSON[] = [];
  if (startAndEndIds.length === 1) {
    // copy single block
    const id = startAndEndIds[0];
    const node = document.nodes[id];
    const nodeDelta = new Delta(node.data.delta);
    const range = documentRange.ranges[id] || { index: 0, length: 0 };
    const isFull = range.index === 0 && range.length === nodeDelta.length();
    if (isFull) {
      result.push(getCopyBlock(id, document, documentRange));
    } else {
      result.push({
        type: BlockType.TextBlock,
        children: [],
        data: {
          delta: getDeltaByRange(nodeDelta, range).ops,
        },
      });
    }
  } else {
    // copy multiple blocks
    const copyIds: string[] = [];
    const [startId, endId] = startAndEndIds;
    const middleIds = getMiddleIds(document, startId, endId);
    copyIds.push(startId, ...middleIds, endId);
    const map = new Map<string, DocumentBlockJSON>();
    copyIds.forEach((id) => {
      const block = getCopyBlock(id, document, documentRange);
      map.set(id, block);
      const node = document.nodes[id];
      const parent = node.parent;
      if (parent && map.has(parent)) {
        map.get(parent)!.children.push(block);
      } else {
        result.push(block);
      }
    });
  }
  setClipboardData({
    json: JSON.stringify(result),
    // TODO: implement plain text and html
    text: '',
    html: '',
  });
});

/**
 * Paste data to document
 * 1. delete range blocks
 * 2. if current block is empty text block, insert paste data below current block and delete current block
 * 3. otherwise:
 *    3.1 split current block, before part merge the first block of paste data and update current block
 *    3.2 after part append to the last block of paste data
 *    3.3 move the first block children of paste data to current block
 *    3.4 delete the first block of paste data
 */
export const pasteThunk = createAsyncThunk<
  void,
  {
    data: BlockCopyData;
    controller: DocumentController;
  }
>('document/paste', async (payload, thunkAPI) => {
  const { getState, dispatch } = thunkAPI;
  const { data, controller } = payload;
  // delete range blocks
  await dispatch(deleteRangeAndInsertThunk({ controller }));

  let pasteData;
  if (data.json) {
    pasteData = JSON.parse(data.json) as DocumentBlockJSON[];
  } else if (data.text) {
    // TODO: implement plain text
  } else if (data.html) {
    // TODO: implement html
  }
  if (!pasteData) return;
  const { document, documentRange } = getState() as RootState;
  const { caret } = documentRange;
  if (!caret) return;
  const currentBlock = document.nodes[caret.id];
  if (!currentBlock.parent) return;
  const pasteBlocks = generateBlocks(pasteData, currentBlock.parent);
  const currentBlockDelta = new Delta(currentBlock.data.delta);
  const type = currentBlock.type;
  const actions = getInsertBlockActions(pasteBlocks, currentBlock.id, controller);
  const firstPasteBlock = pasteBlocks[0];
  const firstPasteBlockChildren = pasteBlocks.filter((block) => block.parent === firstPasteBlock.id);

  const lastPasteBlock = pasteBlocks[pasteBlocks.length - 1];
  if (type === BlockType.TextBlock && currentBlockDelta.length() === 0) {
    // move current block children to first paste block
    const children = document.children[currentBlock.children].map((id) => document.nodes[id]);
    const firstPasteBlockLastChild =
      firstPasteBlockChildren.length > 0 ? firstPasteBlockChildren[firstPasteBlockChildren.length - 1] : undefined;
    const prevId = firstPasteBlockLastChild ? firstPasteBlockLastChild.id : undefined;
    const moveChildrenActions = getMoveChildrenActions({
      target: firstPasteBlock,
      children,
      controller,
      prevId,
    });
    actions.push(...moveChildrenActions);
    // delete current block
    actions.push(controller.getDeleteAction(currentBlock));
    await controller.applyActions(actions);
    // set caret to the end of the last paste block
    dispatch(
      rangeActions.setCaret({
        id: lastPasteBlock.id,
        index: new Delta(lastPasteBlock.data.delta).length(),
        length: 0,
      })
    );
    return;
  }

  // split current block
  const currentBeforeDelta = getDeltaByRange(currentBlockDelta, { index: 0, length: caret.index });
  const currentAfterDelta = getDeltaByRange(currentBlockDelta, {
    index: caret.index,
    length: currentBlockDelta.length() - caret.index,
  });

  let newCaret;
  const firstPasteBlockDelta = new Delta(firstPasteBlock.data.delta);
  const lastPasteBlockDelta = new Delta(lastPasteBlock.data.delta);
  let mergeDelta = new Delta(currentBeforeDelta.ops).concat(firstPasteBlockDelta);
  if (firstPasteBlock.id !== lastPasteBlock.id) {
    // update the last block of paste data
    actions.push(getAppendBlockDeltaAction(lastPasteBlock, currentAfterDelta, false, controller));
    newCaret = {
      id: lastPasteBlock.id,
      index: lastPasteBlockDelta.length(),
      length: 0,
    };
  } else {
    newCaret = {
      id: currentBlock.id,
      index: mergeDelta.length(),
      length: 0,
    };
    mergeDelta = mergeDelta.concat(currentAfterDelta);
  }

  // update current block and merge the first block of paste data
  actions.push(
    controller.getUpdateAction({
      ...currentBlock,
      data: {
        ...currentBlock.data,
        delta: mergeDelta.ops,
      },
    })
  );

  // move the first block children of paste data to current block
  if (firstPasteBlockChildren.length > 0) {
    const moveChildrenActions = getMoveChildrenActions({
      target: currentBlock,
      children: firstPasteBlockChildren,
      controller,
    });
    actions.push(...moveChildrenActions);
  }

  // delete first block of paste data
  actions.push(controller.getDeleteAction(firstPasteBlock));
  await controller.applyActions(actions);
  // set caret to the end of the last paste block
  if (!newCaret) return;

  dispatch(rangeActions.setCaret(newCaret));
});
