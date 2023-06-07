import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { DocumentState } from '$app/interfaces/document';
import Delta from 'quill-delta';
import { linkPopoverActions, rangeActions } from '$app_reducers/document/slice';
import { getDeltaByRange } from '$app/utils/document/delta';
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
  const nodeDelta = new Delta(node.data.delta);

  const diffDelta = new Delta().retain(selection.index).delete(selection.length).insert(title, {
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
  // update paint range
  dispatch(
    rangeActions.setRange({
      id,
      rangeStatic: newSelection,
    })
  );
});

export const newLinkThunk = createAsyncThunk<
  void,
  {
    controller: DocumentController;
  }
>('document/newLink', async (payload, thunkAPI) => {
  const { controller } = payload;
  const { getState, dispatch } = thunkAPI;
  const { documentRange, document } = getState() as RootState;

  const { caret } = documentRange;
  if (!caret) return;
  const id = caret.id;
  const selection = {
    index: caret.index,
    length: caret.length,
  };
  const block = document.nodes[id];
  const delta = getDeltaByRange(new Delta(block.data.delta), selection);
  const op = delta.ops.find((op) => op.attributes?.href);
  const href = (op?.attributes?.href as string) || 'https://';

  const windowSelection = window.getSelection();
  if (!windowSelection) return;
  const title = windowSelection.toString();
  const range = windowSelection.rangeCount > 0 ? windowSelection.getRangeAt(0) : null;
  if (!range) return;
  const rect = range.getBoundingClientRect();

  dispatch(
    linkPopoverActions.setLinkPopover({
      anchorPosition: {
        top: rect.top + rect.height,
        left: rect.left + rect.width / 2,
      },
      id,
      selection,
      title,
      href,
      open: true,
    })
  );
  dispatch(updateLinkThunk({ id, title, href, controller, selection }));
});
