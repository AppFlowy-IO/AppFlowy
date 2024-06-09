import { createContext, useContext } from 'react';

export const OpenMenuContext = createContext<string | null>(null);

export const useOpenMenu = (id: string) => {
  const context = useContext(OpenMenuContext);

  return context === id;
};
