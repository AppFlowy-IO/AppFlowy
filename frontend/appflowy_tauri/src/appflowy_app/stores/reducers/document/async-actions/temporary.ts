import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME, EQUATION_PLACEHOLDER, RANGE_NAME, TEMPORARY_NAME } from '$app/constants/document/name';
import { getDeltaByRange, getDeltaText } from '$app/utils/document/delta';
import Delta from 'quill-delta';
import { TemporaryState, TemporaryType } from '$app/interfaces/document';
import { temporaryActions } from '$app_reducers/document/temporary_slice';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { rangeActions } from '$app_reducers/document/slice';

export const createTemporary = createAsyncThunk(
  'document/temporary/create',
  async (payload: { docId: string; type?: TemporaryType; state?: TemporaryState }, thunkAPI) => {
    const { docId, type } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    let temporaryState = payload.state;

    if (!temporaryState && type) {
      const caret = state[RANGE_NAME][docId].caret;

      if (!caret) {
        return;
      }

      const { id, index, length } = caret;
      const selection = {
        index,
        length,
      };
      const node = state[DOCUMENT_NAME][docId].nodes[id];
      const nodeDelta = new Delta(node.data?.delta);
      const rangeDelta = getDeltaByRange(nodeDelta, selection);
      const text = getDeltaText(rangeDelta);

      temporaryState = {
        id,
        selection,
        selectedText: text,
        type,
        data: {
          latex: text,
        },
      };
    }

    if (!temporaryState) return;
    dispatch(rangeActions.initialState(docId));

    dispatch(temporaryActions.setTemporaryState({ id: docId, state: temporaryState }));
  }
);

export const formatTemporary = createAsyncThunk(
  'document/temporary/format',
  async (payload: { controller: DocumentController }, thunkAPI) => {
    const { controller } = payload;
    const docId = controller.documentId;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    const temporaryState = state[TEMPORARY_NAME][docId];

    if (!temporaryState) {
      return;
    }

    const { id, selection, type, data } = temporaryState;
    const node = state[DOCUMENT_NAME][docId].nodes[id];
    const nodeDelta = new Delta(node.data?.delta);
    const { index, length } = selection;
    const diffDelta: Delta = new Delta();
    let newSelection;

    switch (type) {
      case TemporaryType.Equation: {
        if (data.latex) {
          newSelection = {
            index: selection.index,
            length: 1,
          };
          diffDelta.retain(index).delete(length).insert(EQUATION_PLACEHOLDER, {
            formula: data.latex,
          });
        } else {
          newSelection = {
            index: selection.index,
            length: 0,
          };
          diffDelta.retain(index).delete(length);
        }

        break;
      }

      default:
        break;
    }

    const newDelta = nodeDelta.compose(diffDelta);

    const updateAction = controller.getUpdateAction({
      ...node,
      data: {
        ...node.data,
        delta: newDelta.ops,
      },
    });

    await controller.applyActions([updateAction]);
    return {
      ...temporaryState,
      selection: newSelection,
    };
  }
);
