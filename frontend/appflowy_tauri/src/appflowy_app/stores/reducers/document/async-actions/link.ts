import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import Delta from 'quill-delta';
import { linkPopoverActions, rangeActions } from '$app_reducers/document/slice';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME, RANGE_NAME, TEXT_LINK_NAME } from '$app/constants/document/name';

export const formatLinkThunk = createAsyncThunk<
  boolean,
  {
    controller: DocumentController;
  }
>('document/formatLink', async (payload, thunkAPI) => {
  const { controller } = payload;
  const { getState } = thunkAPI;
  const docId = controller.documentId;
  const state = getState() as RootState;
  const documentState = state[DOCUMENT_NAME][docId];
  const linkPopover = state[TEXT_LINK_NAME][docId];

  if (!linkPopover) return false;
  const { selection, id, href, title = '' } = linkPopover;

  if (!selection || !id) return false;
  const node = documentState.nodes[id];
  const nodeDelta = new Delta(node.data?.delta);
  const index = selection.index || 0;
  const length = selection.length || 0;
  const regex = new RegExp(/^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*\/?$/);

  if (href !== undefined && !regex.test(href)) {
    return false;
  }

  const diffDelta = new Delta().retain(index).delete(length).insert(title, {
    href,
  });

  const newDelta = nodeDelta.compose(diffDelta);

  const updateAction = controller.getUpdateAction({
    ...node,
    data: {
      ...node.data,
      delta: newDelta.ops,
    },
  });

  await controller.applyActions([updateAction]);
  return true;
});

export const newLinkThunk = createAsyncThunk<
  void,
  {
    docId: string;
  }
>('document/newLink', async ({ docId }, thunkAPI) => {
  const { getState, dispatch } = thunkAPI;
  const state = getState() as RootState;
  const documentState = state[DOCUMENT_NAME][docId];
  const documentRange = state[RANGE_NAME][docId];

  const { caret } = documentRange;

  if (!caret) return;
  const { index, length, id } = caret;

  const block = documentState.nodes[id];
  const delta = new Delta(block.data.delta).slice(index, index + length);
  const op = delta.ops.find((op) => op.attributes?.href);
  const href = op?.attributes?.href as string;

  const domSelection = window.getSelection();

  if (!domSelection) return;
  const domRange = domSelection.rangeCount > 0 ? domSelection.getRangeAt(0) : null;

  if (!domRange) return;
  const title = domSelection.toString();
  const { top, left, height, width } = domRange.getBoundingClientRect();

  dispatch(rangeActions.initialState(docId));
  dispatch(
    linkPopoverActions.setLinkPopover({
      docId,
      linkState: {
        anchorPosition: {
          top: top + height,
          left: left + width / 2,
        },
        id,
        selection: {
          index,
          length,
        },
        title,
        href,
        open: true,
      },
    })
  );
});
