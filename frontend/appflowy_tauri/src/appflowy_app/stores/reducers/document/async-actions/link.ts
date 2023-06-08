import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { DocumentState } from '$app/interfaces/document';
import Delta from 'quill-delta';
import { linkPopoverActions } from '$app_reducers/document/slice';
import { getDeltaByRange, getDeltaText } from '$app/utils/document/delta';
import { RootState } from '$app/stores/store';

export const updateLinkThunk = createAsyncThunk<
  void,
  {
    id: string;
    href?: string;
    title: string;
    selection: {
      index: number;
      length: number;
    };
    controller: DocumentController;
  }
>('document/updateLink', async (payload, thunkAPI) => {
  const { id, href, title, controller, selection } = payload;
  const { getState, dispatch } = thunkAPI;
  const state = (getState() as { document: DocumentState }).document;
  const node = state.nodes[id];
  const delta = new Delta(node.data?.delta);
  const index = selection.index || 0;
  const length = selection.length || 0;
  const beforeDelta = delta.slice(0, index);
  const afterDelta = delta.slice(index + length);
  const rangeDelta = delta.slice(index, index + length);
  const toggleFormatDelta = new Delta(
    rangeDelta.ops.map((op) => {
      const attributes = {
        ...op.attributes,
        href: href,
        title: title,
      };
      return {
        insert: op.insert,
        attributes: attributes,
      };
    })
  );
  const newDelta = beforeDelta.concat(toggleFormatDelta).concat(afterDelta);

  const updateAction = controller.getUpdateAction({
    ...node,
    data: {
      ...node.data,
      delta: newDelta.ops,
    },
  });
  const newSelection = {
    index: selection.index,
    length: title.length,
  };
  await controller.applyActions([updateAction]);
  dispatch(
    linkPopoverActions.updateLinkPopover({
      id,
      href,
      title,
      selection: newSelection,
    })
  );
});

export const newLinkThunk = createAsyncThunk<void>('document/newLink', async (payload, thunkAPI) => {
  const { getState, dispatch } = thunkAPI;
  const { documentRange, document } = getState() as RootState;

  const { caret } = documentRange;
  if (!caret) return;
  const { index, length, id } = caret;

  const block = document.nodes[id];
  const delta = getDeltaByRange(new Delta(block.data.delta), {
    index,
    length,
  });
  const op = delta.ops.find((op) => op.attributes?.href);
  const href = (op?.attributes?.href as string) || 'https://';
  const rangeDelta = delta.slice(index, index + length);
  const title = getDeltaText(rangeDelta);
  const domSelection = window.getSelection();
  if (!domSelection) return;
  const domRange = domSelection.rangeCount > 0 ? domSelection.getRangeAt(0) : null;
  if (!domRange) return;
  const domRect = domRange.getBoundingClientRect();

  dispatch(
    linkPopoverActions.setLinkPopover({
      anchorPosition: {
        top: domRect.top + domRect.height,
        left: domRect.left + domRect.width / 2,
      },
      id,
      selection: {
        index,
        length,
      },
      title,
      href,
      open: true,
    })
  );
});
