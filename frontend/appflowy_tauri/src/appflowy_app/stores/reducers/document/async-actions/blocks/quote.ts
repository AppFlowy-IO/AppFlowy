import { createAsyncThunk } from '@reduxjs/toolkit';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { BlockType } from '$app/interfaces/document';
import { turnToBlockThunk } from '$app_reducers/document/async-actions/turn_to';
import { Editor } from 'slate';
import { getQuoteDataFromEditor } from '$app/utils/document/blocks/quote';

/**
 * transform to quote block
 * 1. insert quote block after current block
 * 2. move children to quote block
 * 3. delete current block
 */
export const turnToQuoteBlockThunk = createAsyncThunk(
  'document/turnToQuoteBlock',
  async (payload: { id: string; editor: Editor; controller: DocumentController }, thunkAPI) => {
    const { id, controller, editor } = payload;
    const { dispatch } = thunkAPI;
    const data = getQuoteDataFromEditor(editor);
    if (!data) return;

    await dispatch(
      turnToBlockThunk({
        id,
        controller,
        type: BlockType.QuoteBlock,
        data,
      })
    );
  }
);
