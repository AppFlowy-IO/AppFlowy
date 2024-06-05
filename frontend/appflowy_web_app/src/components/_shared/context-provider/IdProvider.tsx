import { useContext, createContext } from 'react';

export const IdContext = createContext<IdProviderProps | null>(null);

interface IdProviderProps {
  objectId: string;
}

export const IdProvider = ({ children, ...props }: IdProviderProps & { children: React.ReactNode }) => {
  return <IdContext.Provider value={props}>{children}</IdContext.Provider>;
};

const defaultIdValue = {} as IdProviderProps;

export function useId() {
  return useContext(IdContext) || defaultIdValue;
}
