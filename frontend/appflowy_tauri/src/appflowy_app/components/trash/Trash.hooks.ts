import { useCallback, useEffect, useMemo, useState } from 'react';
import { TrashController } from '$app/stores/effects/workspace/trash/controller';
import { useAppDispatch, useAppSelector } from '@/appflowy_app/stores/store';
import { trashActions, trashPBToTrash } from '$app_reducers/trash/slice';

export function useLoadTrash() {
  const trash = useAppSelector((state) => state.trash.list);
  const dispatch = useAppDispatch();
  const controller = useMemo(() => {
    return new TrashController();
  }, []);

  const initializeTrash = useCallback(async () => {
    const trash = await controller.getTrash();

    dispatch(trashActions.initTrash(trash.map(trashPBToTrash)));
  }, [controller, dispatch]);

  const subscribeToTrash = useCallback(async () => {
    controller.subscribe({
      onTrashChanged: (trash) => {
        dispatch(trashActions.onTrashChanged(trash.map(trashPBToTrash)));
      },
    });
  }, [controller, dispatch]);

  useEffect(() => {
    void (async () => {
      await initializeTrash();
      await subscribeToTrash();
    })();
  }, [initializeTrash, subscribeToTrash]);

  useEffect(() => {
    return () => {
      controller.dispose();
    };
  }, [controller]);

  return {
    trash,
  };
}

export function useTrashActions() {
  const [restoreAllDialogOpen, setRestoreAllDialogOpen] = useState(false);
  const [deleteAllDialogOpen, setDeleteAllDialogOpen] = useState(false);

  const controller = useMemo(() => {
    return new TrashController();
  }, []);

  useEffect(() => {
    return () => {
      controller.dispose();
    };
  }, [controller]);

  const onClickRestoreAll = () => {
    setRestoreAllDialogOpen(true);
  };

  const onClickDeleteAll = () => {
    setDeleteAllDialogOpen(true);
  };

  const closeDialog = () => {
    setRestoreAllDialogOpen(false);
    setDeleteAllDialogOpen(false);
  };

  return {
    onPutback: async (id: string) => {
      await controller.putback(id);
    },
    onDelete: async (ids: string[]) => {
      await controller.delete(ids);
    },
    onDeleteAll: async () => {
      await controller.deleteAll();
    },
    onRestoreAll: async () => {
      await controller.restoreAll();
    },
    onClickRestoreAll,
    onClickDeleteAll,
    restoreAllDialogOpen,
    deleteAllDialogOpen,
    closeDialog,
  };
}
