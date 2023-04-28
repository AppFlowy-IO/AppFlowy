import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { useCallback, useContext } from 'react';
import { insertAfterNodeThunk, deleteNodeThunk } from '@/appflowy_app/stores/reducers/document/async_actions';

export enum ActionType {
  InsertAfter = 'insertAfter',
  Remove = 'remove',
}
export function useActions(id: string, type: ActionType) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const insertAfter = useCallback(async () => {
    if (!controller) return;
    await dispatch(insertAfterNodeThunk({ id, controller }));
  }, [id, controller, dispatch]);

  const remove = useCallback(async () => {
    if (!controller) return;
    await dispatch(deleteNodeThunk({ id, controller }));
  }, [id, dispatch]);

  if (type === ActionType.InsertAfter) {
    return insertAfter;
  }
  if (type === ActionType.Remove) {
    return remove;
  }
  return;
}
