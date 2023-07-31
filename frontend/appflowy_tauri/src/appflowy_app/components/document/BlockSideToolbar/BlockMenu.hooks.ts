import { useAppDispatch } from '$app/stores/store';
import { useCallback } from 'react';
import { duplicateBelowNodeThunk } from '$app_reducers/document/async-actions/blocks/duplicate';
import { deleteNodeThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useBlockMenu(id: string) {
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();

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
