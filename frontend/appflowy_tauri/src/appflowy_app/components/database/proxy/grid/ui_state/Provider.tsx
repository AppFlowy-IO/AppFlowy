import React, { useEffect } from 'react';
import { GridUIContext, useProxyGridUIState } from '$app/components/database/proxy/grid/ui_state/actions';

function GridUIProvider({ children, isActivated }: { children: React.ReactNode; isActivated: boolean }) {
  const context = useProxyGridUIState();

  useEffect(() => {
    context.isActivated = isActivated;
  }, [isActivated, context]);

  return <GridUIContext.Provider value={context}>{children}</GridUIContext.Provider>;
}

export default GridUIProvider;
