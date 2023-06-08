import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { TextAction } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import Delta from 'quill-delta';

export const getFormatActiveThunk = createAsyncThunk<boolean, TextAction>(
  'document/getFormatActive',
  async (format, thunkAPI) => {
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const { document, documentRange } = state;
    const { ranges } = documentRange;
    const match = (delta: Delta, format: TextAction) => {
      return delta.ops.every((op) => op.attributes?.[format] === true);
    };
    return Object.entries(ranges).every(([id, range]) => {
      const node = document.nodes[id];
      const delta = new Delta(node.data?.delta);
      const index = range?.index || 0;
      const length = range?.length || 0;
      const rangeDelta = delta.slice(index, index + length);

      return match(rangeDelta, format);
    });
  }
);

export const toggleFormatThunk = createAsyncThunk(
  'document/toggleFormat',
  async (payload: { format: TextAction; controller: DocumentController; isActive?: boolean }, thunkAPI) => {
    const { getState, dispatch } = thunkAPI;
    const { format, controller } = payload;
    let isActive = payload.isActive;
    if (isActive === undefined) {
      const { payload: active } = await dispatch(getFormatActiveThunk(format));
      isActive = !!active;
    }
    const state = getState() as RootState;
    const { document } = state;
    const { ranges } = state.documentRange;

    const toggle = (delta: Delta, format: TextAction) => {
      const newOps = delta.ops.map((op) => {
        const attributes = {
          ...op.attributes,
          [format]: isActive ? undefined : true,
        };
        return {
          insert: op.insert,
          attributes: attributes,
        };
      });
      return new Delta(newOps);
    };

    const actions = Object.entries(ranges).map(([id, range]) => {
      const node = document.nodes[id];
      const delta = new Delta(node.data?.delta);
      const index = range?.index || 0;
      const length = range?.length || 0;
      const beforeDelta = delta.slice(0, index);
      const afterDelta = delta.slice(index + length);
      const rangeDelta = delta.slice(index, index + length);
      const toggleFormatDelta = toggle(rangeDelta, format);
      const newDelta = beforeDelta.concat(toggleFormatDelta).concat(afterDelta);

      return controller.getUpdateAction({
        ...node,
        data: {
          ...node.data,
          delta: newDelta.ops,
        },
      });
    });
    await controller.applyActions(actions);
  }
);
