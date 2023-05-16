import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { TextAction, TextDelta, TextSelection } from '$app/interfaces/document';
import { getAfterRangeDelta, getBeforeRangeDelta, getRangeDelta } from '$app/utils/document/blocks/text/delta';
import { DocumentController } from '$app/stores/effects/document/document_controller';

export const getFormatActiveThunk = createAsyncThunk<boolean, TextAction>(
  'document/getFormatActive',
  async (format, thunkAPI) => {
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const { document } = state;
    const { selection, anchor, focus } = state.documentRangeSelection;

    const match = (delta: TextDelta[], format: TextAction) => {
      return delta.some((op) => op.attributes?.[format] === true);
    };
    return selection.some((id) => {
      const node = document.nodes[id];
      let delta = node.data?.delta as TextDelta[];
      if (!delta) return false;

      if (id === anchor?.id) {
        delta = getRangeDelta(delta, anchor.selection);
      } else if (id === focus?.id) {
        delta = getRangeDelta(delta, focus.selection);
      }
      return match(delta, format);
    });
  }
);

export const toggleFormatThunk = createAsyncThunk(
  'document/toggleFormat',
  async (payload: { format: TextAction; controller: DocumentController }, thunkAPI) => {
    const { getState } = thunkAPI;
    const { format, controller } = payload;
    const state = getState() as RootState;
    const { document } = state;
    const { selection, anchor, focus } = state.documentRangeSelection;

    const toggle = (delta: TextDelta[], format: TextAction) => {
      const isActive = delta.every((op) => op.attributes?.[format] === true);

      return delta.map((op) => {
        const attributes = {
          ...op.attributes,
          [format]: isActive ? undefined : true,
        };
        return {
          insert: op.insert,
          attributes: attributes,
        };
      });
    };

    const splitDelta = (delta: TextDelta[], selection: TextSelection) => {
      const before = getBeforeRangeDelta(delta, selection);
      const after = getAfterRangeDelta(delta, selection);
      let middle = getRangeDelta(delta, selection);

      middle = toggle(middle, format);

      return [...before, ...middle, ...after];
    };

    const set = new Set(selection);

    const actions = Array.from(set).map((id) => {
      const node = document.nodes[id];
      let delta = node.data?.delta as TextDelta[];
      if (!delta) return controller.getUpdateAction(node);

      if (id === anchor?.id) {
        delta = splitDelta(delta, anchor.selection);
      } else if (id === focus?.id) {
        delta = splitDelta(delta, focus.selection);
      } else {
        delta = toggle(delta, format);
      }

      return controller.getUpdateAction({
        ...node,
        data: {
          ...node.data,
          delta,
        },
      });
    });
    await controller.applyActions(actions);
  }
);
