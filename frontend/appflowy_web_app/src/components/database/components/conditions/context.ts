import { createContext, useContext } from 'react';

interface DatabaseConditionsContextType {
  expanded: boolean;
  toggleExpanded: () => void;
}

export function useConditionsContext() {
  return useContext(DatabaseConditionsContext);
}

export const DatabaseConditionsContext = createContext<DatabaseConditionsContextType | undefined>(undefined);
