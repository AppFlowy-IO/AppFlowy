import { BlockType, DocumentState } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { outdentNodeThunk } from './outdent';
import { turnToTextBlockThunk } from '$app_reducers/document/async-actions/blocks/text/turn_to';
import { mergeToPrevLineThunk } from '$app_reducers/document/async-actions/blocks/text/merge';
import { ReactEditor } from 'slate-react';

/**
 * 1. If current node is not text block, turn it to text block
 * 2. If current node is text block
 *    2.1 If the current node has next node, merge it to the previous line
 *    2.2 If the parent is root, merge it to the previous line
 *    2.3 If the parent is not root and has no next node, outdent it
 */
export const backspaceNodeThunk = createAsyncThunk(
  'document/backspaceNode',
  async (payload: { id: string; controller: DocumentController; editor: ReactEditor }, thunkAPI) => {
    const { id, controller, editor } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node.parent) return;
    const parent = state.nodes[node.parent];
    const children = state.children[parent.children];
    const index = children.indexOf(id);
    const nextNodeId = children[index + 1];
    // turn to text block
    if (node.type !== BlockType.TextBlock) {
      await dispatch(turnToTextBlockThunk({ id, controller }));
      return;
    }
    const parentIsRoot = !parent.parent;
    // merge to previous line when parent is root
    if (parentIsRoot || nextNodeId) {
      // merge to previous line
      ReactEditor.deselect(editor);
      await dispatch(mergeToPrevLineThunk({ id, controller, deleteCurrentNode: true }));
      return;
    }
    // outdent
    await dispatch(outdentNodeThunk({ id, controller }));
  }
);
