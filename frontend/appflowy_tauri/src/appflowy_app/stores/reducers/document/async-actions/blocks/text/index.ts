import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { DocumentState } from '$app/interfaces/document';
import { newTextBlock } from '$app/utils/document/blocks/text';
import { setCursorBeforeThunk } from '$app_reducers/document/async-actions/cursor';

export const turnToTextBlockThunk = createAsyncThunk(
  'document/turnToTextBlock',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;

    const node = state.nodes[id];
    if (!node.parent) return;

    const parent = state.nodes[node.parent];
    const children = state.children[node.children].map((id) => state.nodes[id]);

    /**
     * transform to text block
     * 1. insert text block after current block
     * 2. move children to text block
     * 3. delete current block
     */

    const textBlock = newTextBlock(parent.id, {
      delta: node.data.delta,
    });
    const insertTextAction = controller.getInsertAction(textBlock, node.id);
    const moveChildrenActions = controller.getMoveChildrenAction(children, textBlock.id, '');
    const deleteAction = controller.getDeleteAction(node);

    // submit actions
    await controller.applyActions([insertTextAction, ...moveChildrenActions, deleteAction]);
    // set cursor
    await dispatch(setCursorBeforeThunk({ id: textBlock.id }));
  }
);
