import { createAsyncThunk } from '@reduxjs/toolkit';
import { Editor } from 'slate';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { DocumentState } from '$app/interfaces/document';
import { getHeadingDataFromEditor, newHeadingBlock } from '$app/utils/document/blocks/heading';
import { setCursorBeforeThunk } from '$app_reducers/document/async-actions/cursor';

export const turnToHeadingBlockThunk = createAsyncThunk(
  'document/turnToHeadingBlock',
  async (payload: { id: string; editor: Editor; controller: DocumentController }, thunkAPI) => {
    const { id, editor, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;

    const node = state.nodes[id];
    if (!node.parent) return;

    const parent = state.nodes[node.parent];
    const children = state.children[node.children].map((id) => state.nodes[id]);

    /**
     * transform to heading block
     * 1. insert heading block after current block
     * 2. move all children to parent after heading block, because heading block can't have children
     * 3. delete current block
     */

    const data = getHeadingDataFromEditor(editor);
    if (!data) return;
    const headingBlock = newHeadingBlock(parent.id, data);
    const insertHeadingAction = controller.getInsertAction(headingBlock, node.id);

    const moveChildrenActions = controller.getMoveChildrenAction(children, parent.id, headingBlock.id);

    const deleteAction = controller.getDeleteAction(node);

    // submit actions
    await controller.applyActions([insertHeadingAction, ...moveChildrenActions, deleteAction]);
    // set cursor
    await dispatch(setCursorBeforeThunk({ id: headingBlock.id }));
  }
);
