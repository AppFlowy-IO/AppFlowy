import { YFolder } from '@/application/collab.type';
import { createContext, useContext } from 'react';

export const FolderContext = createContext<YFolder | null>(null);

export const useFolderContext = () => {
  return useContext(FolderContext);
};
