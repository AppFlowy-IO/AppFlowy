import { YFolder } from '@/application/collab.type';
import { FolderContext } from '@/application/folder-yjs';

export const FolderProvider: React.FC<{ folder: YFolder | null; children?: React.ReactNode }> = ({
  folder,
  children,
}) => {
  return <FolderContext.Provider value={folder}>{children}</FolderContext.Provider>;
};
