import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { TextAction } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import Delta from 'quill-delta';
import { DOCUMENT_NAME, RANGE_NAME } from '$app/constants/document/name';

type FormatValues = Record<string, (boolean | string | undefined)[]>;

export const getFormatValuesThunk = createAsyncThunk(
  'document/getFormatValues',
  ({ docId, format }: { docId: string; format: TextAction }, thunkAPI) => {
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const document = state[DOCUMENT_NAME][docId];
    const documentRange = state[RANGE_NAME][docId];
    const { ranges } = documentRange;
    const mapAttrs = (delta: Delta, format: TextAction) => {
      return delta.ops.map((op) => op.attributes?.[format] as boolean | string | undefined);
    };

    const formatValues: FormatValues = {};

    Object.entries(ranges).forEach(([id, range]) => {
      const node = document.nodes[id];
      const delta = new Delta(node.data?.delta);
      const index = range?.index || 0;
      const length = range?.length || 0;
      const rangeDelta = delta.slice(index, index + length);

      formatValues[id] = mapAttrs(rangeDelta, format);
    });
    return formatValues;
  }
);

export const getFormatActiveThunk = createAsyncThunk<
  boolean,
  {
    format: TextAction;
    docId: string;
  }
>('document/getFormatActive', async ({ format, docId }, thunkAPI) => {
  const { dispatch } = thunkAPI;
  const { payload } = (await dispatch(getFormatValuesThunk({ docId, format }))) as {
    payload: FormatValues;
  };

  return Object.values(payload).every((values) => {
    return values.every((value) => {
      return value !== undefined;
    });
  });
});

export const toggleFormatThunk = createAsyncThunk(
  'document/toggleFormat',
  async (payload: { format: TextAction; controller: DocumentController; isActive?: boolean }, thunkAPI) => {
    const { dispatch } = thunkAPI;
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

    const formatValue = isActive ? null : true;
    await dispatch(formatThunk({ format, value: formatValue, controller }));
  }
);

export const formatThunk = createAsyncThunk(
  'document/format',
  async (payload: { format: TextAction; value: string | boolean | null; controller: DocumentController }, thunkAPI) => {
    const { getState } = thunkAPI;
    const { format, controller, value } = payload;
    const docId = controller.documentId;
    const state = getState() as RootState;
    const document = state[DOCUMENT_NAME][docId];
    const documentRange = state[RANGE_NAME][docId];
    const { ranges } = documentRange;

    const actions = Object.entries(ranges).map(([id, range]) => {
      const node = document.nodes[id];
      const delta = new Delta(node.data?.delta);
      const index = range?.index || 0;
      const length = range?.length || 0;
      const diffDelta: Delta = new Delta();
      diffDelta.retain(index).retain(length, { [format]: value });
      const newDelta = delta.compose(diffDelta);

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
