import { useCallback, useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '@/appflowy_app/stores/store';
import { trashActions, trashPBToTrash } from '$app_reducers/trash/slice';
import { subscribeNotifications } from '$app/application/notification';
import { FolderNotification } from '@/services/backend';
import { deleteTrashItem, getTrash, putback, deleteAll, restoreAll } from '$app/application/folder/trash.service';

export function useLoadTrash() {
  const trash = useAppSelector((state) => state.trash.list);
  const dispatch = useAppDispatch();

  const initializeTrash = useCallback(async () => {
    const trash = await getTrash();

    dispatch(trashActions.initTrash(trash.map(trashPBToTrash)));
  }, [dispatch]);

  useEffect(() => {
    void initializeTrash();
  }, [initializeTrash]);

  useEffect(() => {
    const unsubscribePromise = subscribeNotifications({
      [FolderNotification.DidUpdateTrash]: async (changeset) => {
        dispatch(trashActions.onTrashChanged(changeset.items.map(trashPBToTrash)));
      },
    });

    return () => {
      void unsubscribePromise.then((fn) => fn());
    };
  }, [dispatch]);

  return {
    trash,
  };
}

export function useTrashActions() {
  const [restoreAllDialogOpen, setRestoreAllDialogOpen] = useState(false);
  const [deleteAllDialogOpen, setDeleteAllDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const [deleteId, setDeleteId] = useState('');

  const onClickRestoreAll = () => {
    setRestoreAllDialogOpen(true);
  };

  const onClickDeleteAll = () => {
    setDeleteAllDialogOpen(true);
  };

  const closeDialog = () => {
    setRestoreAllDialogOpen(false);
    setDeleteAllDialogOpen(false);
    setDeleteDialogOpen(false);
  };

  const onClickDelete = (id: string) => {
    setDeleteId(id);
    setDeleteDialogOpen(true);
  };

  return {
    onClickDelete,
    deleteDialogOpen,
    deleteId,
    onPutback: putback,
    onDelete: deleteTrashItem,
    onDeleteAll: deleteAll,
    onRestoreAll: restoreAll,
    onClickRestoreAll,
    onClickDeleteAll,
    restoreAllDialogOpen,
    deleteAllDialogOpen,
    closeDialog,
  };
}
