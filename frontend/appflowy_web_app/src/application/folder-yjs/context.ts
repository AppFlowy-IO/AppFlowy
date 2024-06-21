import { ViewLayout, YFolder, YjsFolderKey } from '@/application/collab.type';
import { createContext, useContext } from 'react';
import { useParams } from 'react-router-dom';

export interface Crumb {
  viewId: string;
  rowId?: string;
  name: string;
  icon: string;
}

export const FolderContext = createContext<{
  folder: YFolder | null;
  onNavigateToView?: (viewId: string) => void;
  crumbs?: Crumb[];
  setCrumbs?: React.Dispatch<React.SetStateAction<Crumb[]>>;
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
