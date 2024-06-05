import { YjsFolderKey, YView } from '@/application/collab.type';
import { useFolderContext } from '@/application/folder-yjs/context';
import { useEffect, useState } from 'react';

export function useViewsIdSelector() {
  const folder = useFolderContext();
  const [viewsId, setViewsId] = useState<string[]>([]);
  const views = folder?.get(YjsFolderKey.views);
  const trash = folder?.get(YjsFolderKey.section)?.get(YjsFolderKey.trash);
  const meta = folder?.get(YjsFolderKey.meta);

  useEffect(() => {
    if (!views) {
      return;
    }

    const trashUid = trash ? Array.from(trash.keys())[0] : null;
    const userTrash = trashUid ? trash?.get(trashUid) : null;

    const collectIds = () => {
      const trashIds = userTrash?.toJSON()?.map((item) => item.id) || [];

      return Array.from(views.keys()).filter((id) => {
        return !trashIds.includes(id) && id !== meta?.get(YjsFolderKey.current_workspace);
      });
    };

    setViewsId(collectIds());
    const observerEvent = () => setViewsId(collectIds());

    views.observe(observerEvent);
    userTrash?.observe(observerEvent);

    return () => {
      views.unobserve(observerEvent);
      userTrash?.unobserve(observerEvent);
    };
  }, [views, trash, meta]);

  return {
    viewsId,
    views,
  };
}

export function useViewSelector(viewId: string) {
  const folder = useFolderContext();
  const [clock, setClock] = useState<number>(0);
  const [view, setView] = useState<YView | null>(null);

  useEffect(() => {
    if (!folder) return;

    const view = folder.get(YjsFolderKey.views)?.get(viewId);

    setView(view || null);
    const observerEvent = () => setClock((prev) => prev + 1);

    view?.observe(observerEvent);

    return () => {
      view?.unobserve(observerEvent);
    };
  }, [folder, viewId]);

  return {
    clock,
    view,
  };
}
