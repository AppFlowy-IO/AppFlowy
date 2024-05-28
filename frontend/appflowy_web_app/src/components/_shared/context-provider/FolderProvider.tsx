import { YFolder } from '@/application/collab.type';
import { Crumb, FolderContext } from '@/application/folder-yjs';

export const FolderProvider: React.FC<{
  folder: YFolder | null;
  children?: React.ReactNode;
  onNavigateToView?: (viewId: string) => void;
  crumbs?: Crumb[];
  setCrumbs?: React.Dispatch<React.SetStateAction<Crumb[]>>;
}> = ({ folder, children, onNavigateToView, crumbs, setCrumbs }) => {
  return (
    <FolderContext.Provider
      value={{
        folder,
        onNavigateToView,
        crumbs,
        setCrumbs,
      }}
    >
      {children}
    </FolderContext.Provider>
  );
};
