import { useMemo, useContext, createContext, useCallback } from 'react';
import { proxy, useSnapshot } from 'valtio';

export interface GridUIContextState {
  hoverRowId: string | null;
  isActivated: boolean;
}

const initialUIState: GridUIContextState = {
  hoverRowId: null,
  isActivated: false,
};

function proxyGridUIState(state: GridUIContextState) {
  return proxy<GridUIContextState>(state);
}

export const GridUIContext = createContext<GridUIContextState>(proxyGridUIState(initialUIState));

export function useProxyGridUIState() {
  const context = useMemo<GridUIContextState>(() => {
    return proxyGridUIState({
      ...initialUIState,
    });
  }, []);

  return context;
}

export function useGridUIStateSelector() {
  return useSnapshot(useContext(GridUIContext));
}

export function useGridUIStateDispatcher() {
  const context = useContext(GridUIContext);
  const setRowHover = useCallback(
    (rowId: string | null) => {
      context.hoverRowId = rowId;
    },
    [context]
  );

  return {
    setRowHover,
  };
}
