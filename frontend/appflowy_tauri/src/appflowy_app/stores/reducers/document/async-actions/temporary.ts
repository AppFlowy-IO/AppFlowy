import { createAsyncThunk } from '@reduxjs/toolkit';
import { RootState } from '$app/stores/store';
import { DOCUMENT_NAME, EQUATION_PLACEHOLDER, RANGE_NAME, TEMPORARY_NAME } from '$app/constants/document/name';
import { getDeltaByRange, getDeltaText } from '$app/utils/document/delta';
import Delta from 'quill-delta';
import { TemporaryState, TemporaryType } from '$app/interfaces/document';
import { temporaryActions } from '$app_reducers/document/temporary_slice';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { rangeActions } from '$app_reducers/document/slice';
import { BlockDeltaOperator } from '$app/utils/document/block_delta';

export const createTemporary = createAsyncThunk(
  'document/temporary/create',
  async (payload: { docId: string; type?: TemporaryType; state?: TemporaryState }, thunkAPI) => {
    const { docId, type } = payload;
    const { dispatch, getState } = thunkAPI;
    const state = getState() as RootState;
    let temporaryState = payload.state;
    const documentState = state[DOCUMENT_NAME][docId];
    const deltaOperator = new BlockDeltaOperator(documentState);

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
      const nodeDelta = deltaOperator.getDeltaWithBlockId(node.id);

      if (!nodeDelta) return;
      const rangeDelta = deltaOperator.sliceDeltaWithBlockId(
        node.id,
        selection.index,
        selection.index + selection.length
      );

      if (!rangeDelta) return;
      const text = deltaOperator.getDeltaText(rangeDelta);

      const data = newDataWithTemporaryType(type, text);

      temporaryState = {
        id,
        selection,
        selectedText: text,
        type,
        data,
      };
    }

    if (!temporaryState) return;
    dispatch(rangeActions.initialState(docId));

    dispatch(temporaryActions.setTemporaryState({ id: docId, state: temporaryState }));
  }
);

function newDataWithTemporaryType(type: TemporaryType, text: string) {
  switch (type) {
    case TemporaryType.Equation:
      return {
        latex: text,
      };
    case TemporaryType.Link:
      return {
        href: '',
        text: text,
      };
    default:
      return {};
  }
}

export const formatTemporary = createAsyncThunk(
  'document/temporary/format',
  async (payload: { controller: DocumentController }, thunkAPI) => {
    const { controller } = payload;
    const docId = controller.documentId;
    const { getState } = thunkAPI;
    const state = getState() as RootState;
    const temporaryState = state[TEMPORARY_NAME][docId];
    const documentState = state[DOCUMENT_NAME][docId];
    const deltaOperator = new BlockDeltaOperator(documentState, controller);

    if (!temporaryState) {
      return;
    }

    const { id, selection, type, data } = temporaryState;
    const { index, length } = selection;
    const diffDelta: Delta = new Delta();
    let newSelection = selection;

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

      case TemporaryType.Link: {
        if (!data.text) return;
        if (!data.href) {
          diffDelta.retain(index).delete(length).insert(data.text);
        } else {
          diffDelta.retain(index).delete(length).insert(data.text, {
            href: data.href,
          });
        }

        newSelection = {
          index: selection.index,
          length: data.text.length,
        };
        break;
      }

      default:
        break;
    }

    const applyTextDeltaAction = deltaOperator.getApplyDeltaAction(id, diffDelta);

    if (!applyTextDeltaAction) return;
    await controller.applyActions([applyTextDeltaAction]);
    return {
      ...temporaryState,
      selection: newSelection,
    };
  }
);
