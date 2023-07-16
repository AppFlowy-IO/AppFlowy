import { useEffect, useMemo, useState } from 'react';
import { TrashController } from '$app/stores/effects/workspace/trash/controller';
import { TrashPB } from '@/services/backend';

export function useLoadTrash() {
  const [trash, setTrash] = useState<TrashPB[]>([]);

  const controller = useMemo(() => {
    return new TrashController();
  }, []);

  useEffect(() => {
    void (async () => {
      const trash = await controller.getTrash();

      setTrash(trash);
    })();
  }, [controller]);

  useEffect(() => {
    controller.subscribe({
      onTrashChanged: (trash) => {
        setTrash(trash);
      },
    });
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

  const closeDislog = () => {
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
    closeDislog,
  };
}
