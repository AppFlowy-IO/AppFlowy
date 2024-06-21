import { YFolder, YjsEditorKey, YjsFolderKey } from '@/application/collab.type';
import { Crumb } from '@/application/folder-yjs';
import { AFConfigContext } from '@/components/app/AppConfig';
import { useCallback, useContext, useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';

export function useLayout() {
  const { workspaceId, objectId } = useParams();
  const [search] = useSearchParams();
  const folderService = useContext(AFConfigContext)?.service?.folderService;
  const [folder, setFolder] = useState<YFolder | null>(null);
  const views = folder?.get(YjsFolderKey.views);
  const view = objectId ? views?.get(objectId) : null;
  const [crumbs, setCrumbs] = useState<Crumb[]>([]);

  const getFolder = useCallback(
    async (workspaceId: string) => {
      const folder = (await folderService?.openWorkspace(workspaceId))
        ?.getMap(YjsEditorKey.data_section)
        .get(YjsEditorKey.folder);

      if (!folder) return;

      console.log(folder.toJSON());
      setFolder(folder);
    },
    [folderService]
  );

  useEffect(() => {
    if (!workspaceId) return;

    void getFolder(workspaceId);
  }, [getFolder, workspaceId]);

  const navigate = useNavigate();

  const handleNavigateToView = useCallback(
    (viewId: string) => {
      const view = folder?.get(YjsFolderKey.views)?.get(viewId);

      if (!view) return;
      navigate(`/view/${workspaceId}/${viewId}`);
    },
    [folder, navigate, workspaceId]
  );

  const onChangeBreadcrumb = useCallback(() => {
    if (!view) return;
    const queue = [view];
    let parentId = view.get(YjsFolderKey.bid);

    while (parentId) {
      const parent = views?.get(parentId);

      if (!parent) break;

      queue.unshift(parent);
      parentId = parent?.get(YjsFolderKey.bid);
    }

    setCrumbs(
      queue
        .map((view) => {
          let icon = view.get(YjsFolderKey.icon);

          try {
            icon = JSON.parse(icon || '')?.value;
          } catch (e) {
            // do nothing
          }

          return {
            viewId: view.get(YjsFolderKey.id),
            name: view.get(YjsFolderKey.name),
            icon: icon || view.get(YjsFolderKey.layout),
          };
        })
        .slice(1)
    );
  }, [view, views]);

  useEffect(() => {
    onChangeBreadcrumb();

    view?.observe(onChangeBreadcrumb);
    views?.observe(onChangeBreadcrumb);

    return () => {
      view?.unobserve(onChangeBreadcrumb);
      views?.unobserve(onChangeBreadcrumb);
    };
  }, [search, onChangeBreadcrumb, view, views]);

  return { folder, handleNavigateToView, crumbs, setCrumbs };
}
