import { useAppDispatch } from '$app/stores/store';
import { useCallback, useContext } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { duplicateBelowNodeThunk } from '$app_reducers/document/async-actions/blocks/duplicate';
import { deleteNodeThunk } from '$app_reducers/document/async-actions';

export function useBlockMenu(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const handleDuplicate = useCallback(async () => {
    if (!controller) return;
    await dispatch(
      duplicateBelowNodeThunk({
        id,
        controller,
      })
    );
  }, [controller, dispatch, id]);

  const handleDelete = useCallback(async () => {
    if (!controller) return;
    await dispatch(
      deleteNodeThunk({
        id,
        controller,
      })
    );
  }, [controller, dispatch, id]);

  return {
    handleDuplicate,
    handleDelete,
  };
}
