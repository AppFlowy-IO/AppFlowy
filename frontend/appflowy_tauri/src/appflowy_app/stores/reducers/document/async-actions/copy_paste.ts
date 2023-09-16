import { createAsyncThunk } from '@reduxjs/toolkit';
import { BlockCopyData } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';

export const copyThunk = createAsyncThunk<
  void,
  {
    isCut?: boolean;
    controller: DocumentController;
    setClipboardData: (data: BlockCopyData) => void;
  }
>('document/copy', async (payload, thunkAPI) => {
  // TODO: Migrate to Rust implementation.
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
  // TODO: Migrate to Rust implementation.
});
