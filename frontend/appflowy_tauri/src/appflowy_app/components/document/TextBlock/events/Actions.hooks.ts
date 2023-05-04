import { useAppDispatch } from '$app/stores/store';
import { useCallback, useContext } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import {
  backspaceNodeThunk,
  indentNodeThunk,
  setCursorNextLineThunk,
  setCursorPreLineThunk,
  splitNodeThunk,
  updateNodeDeltaThunk,
} from '$app_reducers/document/async-actions';
import { TextDelta, TextSelection } from '$app/interfaces/document';
import { documentActions } from '$app_reducers/document/slice';
import { Editor } from 'slate';

export function useActions(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const indentAction = useCallback(async () => {
    if (!controller) return;
    await dispatch(
      indentNodeThunk({
        id,
        controller,
      })
    );
  }, [id, controller]);

  const backSpaceAction = useCallback(async () => {
    if (!controller) return;
    await dispatch(backspaceNodeThunk({ id, controller }));
  }, [controller, id]);

  const splitAction = useCallback(
    async (retain: TextDelta[], insert: TextDelta[]) => {
      if (!controller) return;
      await dispatch(splitNodeThunk({ id, retain, insert, controller }));
    },
    [controller, id]
  );

  const wrapAction = useCallback(
    async (delta: TextDelta[], selection: TextSelection) => {
      if (!controller) return;
      await dispatch(updateNodeDeltaThunk({ id, delta, controller }));
      // This is a hack to make sure the selection is updated after next render
      dispatch(documentActions.setTextSelection({ blockId: id, selection }));
    },
    [controller, id]
  );

  const focusPreLineAction = useCallback(
    async (params: { editor: Editor; focusEnd?: boolean }) => {
      await dispatch(setCursorPreLineThunk({ id, ...params }));
    },
    [id]
  );

  const focusNextLineAction = useCallback(
    async (params: { editor: Editor; focusStart?: boolean }) => {
      await dispatch(setCursorNextLineThunk({ id, ...params }));
    },
    [id]
  );

  return {
    indentAction,
    backSpaceAction,
    splitAction,
    wrapAction,
    focusPreLineAction,
    focusNextLineAction,
  };
}
