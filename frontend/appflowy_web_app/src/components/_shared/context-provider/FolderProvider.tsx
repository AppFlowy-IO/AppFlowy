import { YFolder } from '@/application/collab.type';
import { Curmb, FolderContext } from '@/application/folder-yjs';

export const FolderProvider: React.FC<{
  folder: YFolder | null;
  children?: React.ReactNode;
  onNavigateToView?: (viewId: string) => void;
  crumbs?: Curmb[];
  setCrumbs?: React.Dispatch<React.SetStateAction<Curmb[]>>;
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
