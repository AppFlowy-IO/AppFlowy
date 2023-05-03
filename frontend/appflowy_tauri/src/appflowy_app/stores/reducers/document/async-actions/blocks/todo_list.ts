import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockType } from '$app/interfaces/document';
import { turnToBlockThunk } from '$app_reducers/document/async-actions/turn_to';
import { Editor } from 'slate';
import { getTodoListDataFromEditor } from '$app/utils/document/blocks/todo_list';

/**
 * transform to todolist block
 * 1. insert todolist block after current block
 * 2. move children to todolist block
 * 3. delete current block
 */
export const turnToTodoListBlockThunk = createAsyncThunk(
  'document/turnToTodoListBlock',
  async (payload: { id: string; editor: Editor; controller: DocumentController }, thunkAPI) => {
    const { id, controller, editor } = payload;
    const { dispatch } = thunkAPI;
    const data = getTodoListDataFromEditor(editor);
    if (!data) return;

    await dispatch(
      turnToBlockThunk({
        id,
        controller,
        type: BlockType.TodoListBlock,
        data,
      })
    );
  }
);
