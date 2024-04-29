import { CollabType } from '@/application/collab.type';
import { useContext, createContext } from 'react';

export const IdContext = createContext<IdProviderProps | null>(null);

interface IdProviderProps {
  workspaceId: string;
  objectId: string;
  collabType: CollabType;
}

export const IdProvider = ({ children, ...props }: IdProviderProps & { children: React.ReactNode }) => {
  return <IdContext.Provider value={props}>{children}</IdContext.Provider>;
};

export function useId() {
  return useContext(IdContext);
}
