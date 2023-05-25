import { createAsyncThunk } from '@reduxjs/toolkit';
import { BlockData, BlockType, DocumentState, TextDelta } from '$app/interfaces/document';
import { insertAfterNodeThunk } from '$app_reducers/document/async-actions/blocks';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { slashCommandActions } from '$app_reducers/document/slice';
import { setCursorBeforeThunk } from '$app_reducers/document/async-actions/cursor';
import { turnToBlockThunk } from '$app_reducers/document/async-actions/turn_to';
import { blockConfig } from '$app/constants/document/config';

/**
 * add block below click
 * 1. if current block is not empty, insert a new block after current block
 * 2. if current block is empty, open slash command below current block
 */
export const addBlockBelowClickThunk = createAsyncThunk(
  'document/addBlockBelowClick',
  async (payload: { id: string; controller: DocumentController }, thunkAPI) => {
    const { id, controller } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node) return;
    const delta = (node.data.delta as TextDelta[]) || [];
    const text = delta.map((d) => d.insert).join('');

    // if current block is not empty, insert a new block after current block
    if (node.type !== BlockType.TextBlock || text !== '') {
      const { payload: newBlockId } = await dispatch(
        insertAfterNodeThunk({ id: id, type: BlockType.TextBlock, controller, data: { delta: [] } })
      );
      if (newBlockId) {
        await dispatch(setCursorBeforeThunk({ id: newBlockId as string }));
        dispatch(slashCommandActions.openSlashCommand({ blockId: newBlockId as string }));
      }
      return;
    }
    // if current block is empty, open slash command
    await dispatch(setCursorBeforeThunk({ id }));
    dispatch(slashCommandActions.openSlashCommand({ blockId: id }));
  }
);

/**
 * slash command action be triggered
 * 1. if current block is empty, operate on current block
 * 2. if current block is not empty, insert a new block after current block and operate on new block
 */
export const triggerSlashCommandActionThunk = createAsyncThunk(
  'document/slashCommandAction',
  async (
    payload: {
      id: string;
      controller: DocumentController;
      props: {
        data?: BlockData<any>;
        type: BlockType;
      };
    },
    thunkAPI
  ) => {
    const { id, controller, props } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node) return;
    const delta = (node.data.delta as TextDelta[]) || [];
    const text = delta.map((d) => d.insert).join('');
    const defaultData = blockConfig[props.type].defaultData;
    if (node.type === BlockType.TextBlock && (text === '' || text === '/')) {
      dispatch(
        turnToBlockThunk({
          id,
          controller,
          type: props.type,
          data: {
            ...defaultData,
            ...props.data,
          },
        })
      );
      return;
    }
    const { payload: newBlockId } = await dispatch(
      insertAfterNodeThunk({
        id,
        controller,
        type: props.type,
        data: {
          ...defaultData,
          ...props.data,
        },
      })
    );
    dispatch(setCursorBeforeThunk({ id: newBlockId as string }));
  }
);
