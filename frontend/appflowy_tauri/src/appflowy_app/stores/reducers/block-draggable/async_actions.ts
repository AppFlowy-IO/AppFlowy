import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { blockDraggableActions, BlockDraggableType } from '$app_reducers/block-draggable/slice';
import { dragThunk } from '$app_reducers/document/async-actions/drag';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { movePageThunk } from '$app_reducers/pages/async_actions';
import { Log } from '$app/utils/log';

export const onDragEndThunk = createAsyncThunk('blockDraggable/onDragEnd', async (payload: void, thunkAPI) => {
  const { getState, dispatch } = thunkAPI;
  const { dragging, draggingId, dropId, insertType, draggingContext, dropContext } = (getState() as RootState)
    .blockDraggable;

  if (!dragging) return;

  dispatch(blockDraggableActions.endDrag());

  if (!draggingId || !dropId || !insertType || !draggingContext || !dropContext) return;
  if (draggingContext.type !== dropContext.type) {
    // TODO: will support this in the future
    Log.info('Unsupported drag this block to different type of block');
    return;
  }

  if (dropContext.type === BlockDraggableType.BLOCK) {
    const docId = dropContext.contextId;

    if (!docId) return;
    await dispatch(
      dragThunk({
        draggingId,
        dropId,
        insertType,
        controller: new DocumentController(docId),
      })
    );
    return;
  }

  if (dropContext.type === BlockDraggableType.PAGE) {
    const workspaceId = dropContext.contextId;

    if (!workspaceId) return;
    await dispatch(
      movePageThunk({
        sourceId: draggingId,
        targetId: dropId,
        insertType,
      })
    );
    return;
  }
});
