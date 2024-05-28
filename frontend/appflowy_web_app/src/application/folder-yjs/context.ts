import { ViewLayout, YFolder, YjsFolderKey } from '@/application/collab.type';
import { createContext, useCallback, useContext } from 'react';
import { useParams } from 'react-router-dom';

export interface Curmb {
  viewId: string;
  rowId?: string;
  name: string;
  icon: string;
}

export const FolderContext = createContext<{
  folder: YFolder | null;
  onNavigateToView?: (viewId: string) => void;
  crumbs?: Curmb[];
  setCrumbs?: React.Dispatch<React.SetStateAction<Curmb[]>>;
} | null>(null);

export const useFolderContext = () => {
  return useContext(FolderContext)?.folder;
};

export const useViewLayout = () => {
  const folder = useFolderContext();
  const { objectId } = useParams();
  const views = folder?.get(YjsFolderKey.views);
  const view = objectId ? views?.get(objectId) : null;

  return Number(view?.get(YjsFolderKey.layout)) as ViewLayout;
};

export const useNavigateToView = () => {
  return useContext(FolderContext)?.onNavigateToView;
};

export const useCrumbs = () => {
  return useContext(FolderContext)?.crumbs;
};

export const usePushCrumb = () => {
  const { setCrumbs } = useContext(FolderContext) || {};

  return useCallback(
    (crumb: Curmb) => {
      setCrumbs?.((prevCrumbs) => [...prevCrumbs, crumb]);
    },
    [setCrumbs]
  );
};
