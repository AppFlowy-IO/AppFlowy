import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { TextAction } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import Delta from 'quill-delta';
import { DOCUMENT_NAME, RANGE_NAME } from '$app/constants/document/name';

export const getFormatActiveThunk = createAsyncThunk<
  boolean,
  {
    format: TextAction;
    docId: string;
  }
>('document/getFormatActive', async ({ format, docId }, thunkAPI) => {
  const { getState } = thunkAPI;
  const state = getState() as RootState;
  const document = state[DOCUMENT_NAME][docId];
  const documentRange = state[RANGE_NAME][docId];
  const { ranges } = documentRange;
  const match = (delta: Delta, format: TextAction) => {
    return delta.ops.every((op) => op.attributes?.[format]);
  };

  return Object.entries(ranges).every(([id, range]) => {
    const node = document.nodes[id];
    const delta = new Delta(node.data?.delta);
    const index = range?.index || 0;
    const length = range?.length || 0;
    const rangeDelta = delta.slice(index, index + length);

    return match(rangeDelta, format);
  });
});

export const toggleFormatThunk = createAsyncThunk(
  'document/toggleFormat',
  async (payload: { format: TextAction; controller: DocumentController; isActive?: boolean }, thunkAPI) => {
    const { getState, dispatch } = thunkAPI;
    const { format, controller } = payload;
    const docId = controller.documentId;
    let isActive = payload.isActive;

    if (isActive === undefined) {
      const { payload: active } = await dispatch(
        getFormatActiveThunk({
          format,
          docId,
        })
      );

      isActive = !!active;
    }

    const formatValue = isActive ? undefined : true;
    const state = getState() as RootState;
    const document = state[DOCUMENT_NAME][docId];
    const documentRange = state[RANGE_NAME][docId];
    const { ranges } = documentRange;

    const toggle = (delta: Delta, format: TextAction, value: string | boolean | undefined) => {
      const newOps = delta.ops.map((op) => {
        const attributes = {
          ...op.attributes,
          [format]: value,
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
      const toggleFormatDelta = toggle(rangeDelta, format, formatValue);
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
