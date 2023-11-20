import { createContext, useContext } from 'react';

const ViewIdContext = createContext('');

export const ViewIdProvider = ViewIdContext.Provider;
export const useViewId = () => useContext(ViewIdContext);
